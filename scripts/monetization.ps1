# monetization.ps1 -- TABI
# Ad slots and contextual affiliate blocks. Dot-sourced by generate-pages.ps1, so
# it shares that script's $config / $siteUrl variables.
#
# Everything here is opt-in and fails closed:
#   * monetization.adsense.clientId empty  -> no ad markup is emitted anywhere,
#     no third-party script is referenced, and the cookie banner stays hidden.
#   * a partner whose url is empty         -> skipped entirely, so an unsigned
#     programme can never ship as a dead or placeholder link.
# That means this file is safe to commit before any affiliate account exists.
#
# NOTE: no BOM, so PowerShell 5.1 reads this as ANSI. ASCII only -- write typographic
# characters as HTML entities (&mdash;, &rsquo;), never literally.

function Get-Mon {
    if ($config.PSObject.Properties.Name -contains 'monetization') { return $config.monetization }
    return $null
}

function Get-AdsenseClient {
    $m = Get-Mon
    if ($m -and $m.adsense -and $m.adsense.clientId) { return $m.adsense.clientId }
    return ''
}

function Test-AdsEnabled { return [bool](Get-AdsenseClient) }

function Get-AdSlot {
    # One AdSense display unit. The <ins> is inert until script.js loads the
    # AdSense library, which it only does after the visitor accepts cookies.
    # min-height is set inline so the slot reserves its space before any script
    # runs and the article text below it does not jump.
    param(
        [string]$slotId,
        [string]$variant = 'in-article',
        [int]$minHeight = 280
    )
    $client = Get-AdsenseClient
    if (-not $client -or -not $slotId) { return '' }

    # data-ad-format=auto everywhere. The "fluid" format belongs to native in-feed
    # units, which also need a data-ad-layout-key generated in the AdSense UI for
    # the specific unit -- without it the tag throws and the slot stays blank.
    return @"
<aside class="ad-slot ad-slot--$variant" aria-label="Advertisement">
  <span class="ad-slot-label">Advertisement</span>
  <ins class="adsbygoogle" style="display:block;min-height:${minHeight}px" data-ad-client="$client" data-ad-slot="$slotId" data-ad-format="auto" data-full-width-responsive="true"></ins>
</aside>
"@
}

function Get-InArticleAd {
    $m = Get-Mon
    if (-not $m) { return '' }
    return (Get-AdSlot $m.adsense.inArticleSlot 'in-article' 280)
}

function Get-EndOfArticleAd {
    $m = Get-Mon
    if (-not $m) { return '' }
    return (Get-AdSlot $m.adsense.endOfArticleSlot 'end' 280)
}

function Get-InFeedAd {
    $m = Get-Mon
    if (-not $m) { return '' }
    return (Get-AdSlot $m.adsense.inFeedSlot 'in-feed' 200)
}

function Get-AdAfterSection {
    # Which section index the mid-article unit follows. 0 or missing disables it.
    $m = Get-Mon
    if ($m -and $m.adsense -and $m.adsense.afterSection) { return [int]$m.adsense.afterSection }
    return 0
}

function Select-Partners {
    # Picks the partners worth showing on one article. Category match counts double
    # so a Things to Buy piece leads with a shop rather than a tour operator.
    # Partners with no url configured are dropped before scoring, so an article
    # never renders an empty "recommended" box.
    param($a)
    $m = Get-Mon
    if (-not $m -or -not $m.partners) { return @() }

    $max = if ($m.maxPartnersPerArticle) { [int]$m.maxPartnersPerArticle } else { 3 }
    $tags = @($a.tags)
    $scored = @()

    foreach ($p in $m.partners) {
        if (-not $p.url) { continue }
        $score = 0
        if ($p.match) {
            if ($p.match.categories -and (@($p.match.categories) -contains $a.category)) { $score += 2 }
            foreach ($t in $tags) {
                if ($p.match.tags -and (@($p.match.tags) -contains $t)) { $score += 1 }
            }
        }
        if ($score -eq 0 -and $p.default) { $score = 1 }
        if ($score -gt 0) {
            $scored += [pscustomobject]@{ partner = $p; score = $score }
        }
    }

    return @($scored | Sort-Object -Property @{ Expression = 'score'; Descending = $true } | Select-Object -First $max | ForEach-Object { $_.partner })
}

function Get-PartnerBox {
    # The contextual affiliate block that sits at the end of an article body.
    # Links carry rel="sponsored" as well as nofollow: Google treats a missing
    # sponsored attribute on paid links as a link-scheme violation.
    param($a)
    $m = Get-Mon
    if (-not $m) { return '' }
    $partners = Select-Partners $a
    if ($partners.Count -eq 0) { return '' }

    $isShopping = ($a.category -eq 'things-to-buy')
    $title = if ($isShopping -and $m.partnerBoxTitleShopping) { $m.partnerBoxTitleShopping }
             elseif ($m.partnerBoxTitle) { $m.partnerBoxTitle }
             else { 'Plan This Trip' }

    $cards = ''
    foreach ($p in $partners) {
        $name = [System.Net.WebUtility]::HtmlEncode($p.name)
        $cta  = if ($p.cta) { [System.Net.WebUtility]::HtmlEncode($p.cta) } else { 'View' }
        $cards += @"
<a class="partner-card" href="$($p.url)" target="_blank" rel="nofollow sponsored noopener noreferrer" data-partner="$($p.id)">
  <span class="partner-kicker">$($p.kicker)</span>
  <span class="partner-name">$name</span>
  <span class="partner-desc">$($p.description)</span>
  <span class="partner-cta">$cta <span aria-hidden="true">&rarr;</span></span>
</a>
"@
    }

    return @"
<aside class="partner-box" aria-labelledby="partner-box-title">
  <p class="partner-box-title" id="partner-box-title">$title</p>
  <div class="partner-grid">$cards</div>
  <p class="partner-box-note">$($m.disclosure)</p>
</aside>
"@
}

function Get-AffiliateDisclosure {
    # Shown at the top of any page that carries a paid link. The FTC wants the
    # disclosure above the first affiliate link, not buried in the footer.
    param($a)
    $m = Get-Mon
    if (-not $m -or -not $m.disclosure) { return '' }
    $hasPartner = (Select-Partners $a).Count -gt 0
    $hasLinks   = ($a.affiliate -and $a.affiliateLinks -and @($a.affiliateLinks).Count -gt 0)
    if (-not ($hasPartner -or $hasLinks)) { return '' }
    return "<p class=""affiliate-disclosure"">$($m.disclosure) <a href=""affiliate.html"">How this works</a>.</p>"
}
