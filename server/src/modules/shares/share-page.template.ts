import {
  RecipeDetailDto,
  RecipeStepBannerDto,
  RecipeStepDto,
} from '../recipes/recipes.service';

/**
 * Rendu HTML de la page publique d'une recette partagée (feature partage-recette).
 * Reprend fidèlement les maquettes du design : feuille A4 2 colongues sur desktop
 * (« page 1 »), carte empilée sur mobile (« page 2 »). Page autonome (styles inline,
 * polices Google Fonts), servie telle quelle par le contrôleur public.
 *
 * Toute donnée issue de la recette est échappée (`esc`) — page publique, jamais de
 * HTML utilisateur injecté brut.
 */

function esc(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function formatNumber(n: number): string {
  return Number.isInteger(n) ? String(n) : String(n).replace('.', ',');
}

/** Libellés FR best-effort des unités (fallback = valeur brute). `null`/vide = sans unité. */
const UNIT_LABELS: Record<string, string> = {
  g: 'g',
  kg: 'kg',
  mg: 'mg',
  ml: 'ml',
  cl: 'cl',
  l: 'l',
  cas: 'c. à s.',
  cac: 'c. à c.',
  pincee: 'pincée',
  piece: '',
  pieces: '',
  unite: '',
  unit: '',
  none: '',
};

function formatQuantity(quantity: number, unit: string): string {
  const label = UNIT_LABELS[unit?.toLowerCase?.()] ?? unit ?? '';
  const qty = formatNumber(quantity);
  return label ? `${qty} ${label}` : qty;
}

function formatDuration(minutes: number): string | null {
  if (!minutes || minutes <= 0) return null;
  if (minutes < 60) return `${minutes} min`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m === 0 ? `${h} h` : `${h} h ${String(m).padStart(2, '0')}`;
}

function bannerHtml(banner: RecipeStepBannerDto | null): string {
  if (!banner) return '';
  return `<div class="banner"><span class="banner-bar"></span><span class="banner-tx">${esc(
    banner.text,
  )}</span></div>`;
}

/** Aplati les étapes (texte + réfs de base dépliées) en lignes numérotées prêtes à rendre. */
function flattenSteps(
  steps: RecipeStepDto[],
): { number: number; description: string; banner: RecipeStepBannerDto | null }[] {
  const out: {
    number: number;
    description: string;
    banner: RecipeStepBannerDto | null;
  }[] = [];
  for (const step of steps) {
    if (step.kind === 'text') {
      out.push({ number: step.number, description: step.description, banner: step.banner });
    } else {
      for (const s of step.steps) {
        out.push({ number: s.number, description: s.description, banner: s.banner });
      }
    }
  }
  return out;
}

function metaTile(icon: string, value: string, label: string): string {
  return `<div class="tile"><span class="tile-ic">${icon}</span><div><div class="tile-v">${esc(
    value,
  )}</div><div class="tile-l">${esc(label)}</div></div></div>`;
}

// Icônes SVG (traits), reprises du design.
const IC_PEOPLE =
  '<svg viewBox="0 0 24 24" fill="none" stroke="#5C7A4C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="8" r="3.2"/><path d="M3.5 20a5.5 5.5 0 0 1 11 0"/><circle cx="17.5" cy="8.5" r="2.6"/><path d="M15.5 19a4.5 4.5 0 0 1 5.5-3.2"/></svg>';
const IC_CLOCK =
  '<svg viewBox="0 0 24 24" fill="none" stroke="#5C7A4C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>';
const IC_POT =
  '<svg viewBox="0 0 24 24" fill="none" stroke="#5C7A4C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.5 3c1.2 1.2.6 2.6 0 3.5-.6.9-1 2 .5 3.5"/><path d="M15 3c1.2 1.2.6 2.6 0 3.5-.6.9-1 2 .5 3.5"/><path d="M4 12h16v1a8 8 0 0 1-16 0z"/><path d="M6 21h12"/></svg>';
const IC_REST =
  '<svg viewBox="0 0 24 24" fill="none" stroke="#5C7A4C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 9-9 7 7 0 0 1-9 9z"/></svg>';
const IC_LEAF =
  '<svg viewBox="0 0 24 24" fill="none" stroke="#6B8E5A" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 3h10a4 4 0 0 1 0 8H4z"/><path d="M4 11v10"/><path d="M18 3c2 2 2 5 0 7"/></svg>';

export function renderSharePage(detail: RecipeDetailDto): string {
  const title = esc(detail.name);
  const description = detail.description ? esc(detail.description) : '';

  const tiles: string[] = [
    metaTile(IC_PEOPLE, formatNumber(detail.servings), 'Personnes'),
  ];
  const prep = formatDuration(detail.prepTime);
  const cook = formatDuration(detail.cookTime);
  const rest = formatDuration(detail.restTime);
  if (prep) tiles.push(metaTile(IC_CLOCK, prep, 'Préparation'));
  if (cook) tiles.push(metaTile(IC_POT, cook, 'Cuisson'));
  if (rest) tiles.push(metaTile(IC_REST, rest, 'Repos'));

  const ingredients = detail.ingredients
    .map(
      (i) =>
        `<li><span class="cb"></span><span><b>${esc(
          formatQuantity(i.quantity, i.unit),
        )}</b> ${esc(i.name)}</span></li>`,
    )
    .join('');

  const flat = flattenSteps(detail.steps);
  const steps = flat
    .map(
      (s) =>
        `<li><span class="num">${s.number}</span><div class="step-body"><div class="step-tx">${esc(
          s.description,
        )}</div>${bannerHtml(s.banner)}</div></li>`,
    )
    .join('');

  const hero = detail.photoUrl
    ? `<img class="hero" src="${esc(detail.photoUrl)}" alt="${title}">`
    : `<div class="hero hero-empty"></div>`;

  const ogImage = detail.photoUrl
    ? `<meta property="og:image" content="${esc(detail.photoUrl)}">`
    : '';

  return `<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title} — Cocotte Minute</title>
<meta property="og:type" content="article">
<meta property="og:title" content="${title}">
${description ? `<meta property="og:description" content="${description}">` : ''}
${ogImage}
<meta name="theme-color" content="#EDEAE2">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,600;12..96,700&family=Hanken+Grotesk:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
  *{box-sizing:border-box;-webkit-font-smoothing:antialiased;}
  html,body{margin:0;background:#EDEAE2;font-family:'Hanken Grotesk',system-ui,sans-serif;color:#1F2933;}
  .desk{min-height:100vh;padding:40px 20px 64px;display:flex;justify-content:center;}
  .sheet{width:100%;max-width:794px;background:#FCFBF8;border:1px solid rgba(31,41,51,.06);border-radius:14px;box-shadow:0 40px 90px -40px rgba(31,41,51,.4);padding:44px 40px 34px;}
  .brand{display:inline-flex;align-items:center;gap:8px;color:#5C7A4C;font-size:12px;font-weight:700;letter-spacing:.18em;text-transform:uppercase;}
  .brand svg{width:16px;height:16px;}
  .head{display:flex;gap:30px;align-items:flex-start;margin-top:14px;}
  .head-tx{flex:1;min-width:0;}
  h1{font-family:'Bricolage Grotesque',sans-serif;font-weight:700;font-size:40px;line-height:1.03;letter-spacing:-.025em;margin:6px 0 0;text-wrap:balance;}
  .lede{font-size:15.5px;line-height:1.6;color:#6B7280;margin:14px 0 0;max-width:440px;}
  .hero{width:280px;height:210px;flex:0 0 auto;border-radius:20px;object-fit:cover;box-shadow:0 18px 36px -22px rgba(31,41,51,.5);}
  .hero-empty{background:linear-gradient(150deg,#EAD9BE,#CBB48C);}
  .meta{display:flex;gap:0;margin-top:30px;border:1px solid #ECEAE3;border-radius:18px;background:#fff;overflow:hidden;flex-wrap:wrap;}
  .tile{flex:1;min-width:140px;display:flex;align-items:center;gap:12px;padding:15px 18px;border-right:1px solid #ECEAE3;}
  .tile:last-child{border-right:none;}
  .tile-ic{width:40px;height:40px;border-radius:12px;background:#F1F5EC;display:flex;align-items:center;justify-content:center;flex:0 0 auto;}
  .tile-ic svg{width:20px;height:20px;}
  .tile-v{font-family:'Bricolage Grotesque',sans-serif;font-weight:700;font-size:18px;line-height:1;}
  .tile-l{font-size:10.5px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:#A79F8B;margin-top:4px;}
  .body{display:flex;gap:38px;margin-top:34px;align-items:flex-start;}
  .col-ing{width:262px;flex:0 0 auto;}
  .col-steps{flex:1;min-width:0;}
  h2{font-family:'Bricolage Grotesque',sans-serif;font-weight:700;font-size:21px;letter-spacing:-.01em;margin:0;display:flex;align-items:baseline;gap:8px;}
  h2 .count{font-size:13px;font-weight:600;color:#B0A892;}
  .rule{width:34px;height:3px;border-radius:3px;background:#6B8E5A;margin:12px 0 16px;}
  ul{list-style:none;margin:0;padding:0;}
  .col-ing li{display:flex;gap:11px;align-items:flex-start;margin-bottom:12px;font-size:14.5px;line-height:1.4;color:#3F4650;}
  .cb{width:17px;height:17px;border-radius:5px;border:1.6px solid #D8D2C4;flex:0 0 auto;margin-top:1px;}
  .col-ing b{color:#5C7A4C;font-weight:700;}
  .col-steps li{display:flex;gap:14px;align-items:flex-start;margin-bottom:18px;}
  .num{width:30px;height:30px;border-radius:999px;background:#1F2933;color:#fff;font-family:'Bricolage Grotesque',sans-serif;font-weight:700;font-size:15px;display:flex;align-items:center;justify-content:center;flex:0 0 auto;}
  .step-body{flex:1;padding-top:3px;}
  .step-tx{font-size:15px;line-height:1.6;color:#33404B;}
  .banner{margin-top:9px;display:flex;border-radius:11px;overflow:hidden;background:#FBF1DE;}
  .banner-bar{width:4px;background:#E8A33D;flex:0 0 auto;}
  .banner-tx{padding:8px 12px;font-size:12.5px;line-height:1.4;color:#8A5A12;font-weight:600;}
  .foot{display:flex;align-items:center;justify-content:space-between;margin-top:34px;padding-top:18px;border-top:1px solid #ECEAE3;gap:14px;flex-wrap:wrap;}
  .foot-l{font-size:12.5px;color:#B0A892;}
  .foot-r{display:inline-flex;align-items:center;gap:8px;color:#8A8574;font-family:'Bricolage Grotesque',sans-serif;font-weight:700;font-size:13.5px;}
  .foot-r svg{width:15px;height:15px;}
  @media (max-width:719px){
    .desk{padding:0;}
    .sheet{border-radius:0;border:none;box-shadow:none;padding:0;}
    .brand{margin:22px 22px 0;}
    .head{flex-direction:column-reverse;gap:0;margin-top:0;}
    .hero{width:100%;height:240px;border-radius:0;box-shadow:none;}
    .head-tx{padding:20px 22px 0;}
    h1{font-size:31px;}
    .lede{max-width:none;}
    .meta{margin:18px 22px 0;}
    .tile{min-width:45%;border-right:none;border-bottom:1px solid #ECEAE3;}
    .body{flex-direction:column;gap:26px;margin:24px 22px 0;}
    .col-ing{width:100%;}
    .foot{margin:24px 22px 30px;}
  }
</style>
</head>
<body>
<div class="desk"><div class="sheet">
  <div class="brand">${IC_LEAF}<span>Recette</span></div>
  <div class="head">
    <div class="head-tx">
      <h1>${title}</h1>
      ${description ? `<p class="lede">${description}</p>` : ''}
    </div>
    ${hero}
  </div>
  <div class="meta">${tiles.join('')}</div>
  <div class="body">
    <div class="col-ing">
      <h2>Ingrédients <span class="count">${detail.ingredients.length}</span></h2>
      <div class="rule"></div>
      <ul>${ingredients || '<li style="color:#A79F8B">Aucun ingrédient</li>'}</ul>
    </div>
    <div class="col-steps">
      <h2>Préparation <span class="count">${flat.length} étape${flat.length > 1 ? 's' : ''}</span></h2>
      <div class="rule"></div>
      <ul>${steps || '<li style="color:#A79F8B">Aucune étape</li>'}</ul>
    </div>
  </div>
  <div class="foot">
    <div class="foot-l">Partagé depuis Cocotte Minute</div>
    <div class="foot-r">${IC_LEAF}<span>Cocotte Minute</span></div>
  </div>
</div></div>
</body>
</html>`;
}
