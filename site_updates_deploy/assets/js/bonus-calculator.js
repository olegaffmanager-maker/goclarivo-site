/* GoClarivo bonus wagering calculator (GoClarivo_plan.docx, section 2).
 * Pure client-side, no server. Formulas:
 *   B = min(D * p/100, Bmax)
 *   W = B*x/c                 (wager from bonus only)
 *   W = (B+D)*x/c              (wager from bonus + deposit)
 *   L = W * (1 - RTP/100)
 *   EV = B - L
 */
(function () {
  "use strict";

  var script = document.currentScript;
  var GEO = script.getAttribute("data-geo");
  var LOCALE = script.getAttribute("data-locale") || "en-US";
  var CURRENCY = script.getAttribute("data-currency") || "USD";

  var VERDICTS = {
    es: { good: "Bono conviene", mid: "Al límite", bad: "Bono no conviene", perDay: "apuestas por día",
          noteGood: "El valor esperado es positivo: estadísticamente el bono aporta más de lo que cuesta liberarlo.",
          noteMid: "El costo esperado está cerca del valor del bono — no es una pérdida grande, pero tampoco una ganancia clara.",
          noteBad: "El costo esperado de liberar el bono supera su valor — estadísticamente no conviene perseguirlo solo por el bono.",
          useBtn: "Calcular este bono", ctaBtn: "Ir al bono", offersTitle: "Bonos con rollover claro" },
    en: { good: "Bonus is worth it", mid: "On the edge", bad: "Bonus is not worth it", perDay: "bets per day",
          noteGood: "The expected value is positive: statistically the bonus is worth more than the cost of clearing it.",
          noteMid: "The expected cost is close to the bonus value — not a big loss, but not a clear win either.",
          noteBad: "The expected cost of clearing the bonus is higher than its value — statistically not worth chasing for the bonus alone.",
          useBtn: "Calculate this bonus", ctaBtn: "Go to bonus", offersTitle: "Bonuses with clear wagering terms" },
    de: { good: "Bonus lohnt sich", mid: "Grenzwertig", bad: "Bonus lohnt sich nicht", perDay: "Wetten pro Tag",
          noteGood: "Der Erwartungswert ist positiv: statistisch bringt der Bonus mehr, als ihn freizuspielen kostet.",
          noteMid: "Die erwarteten Kosten liegen nah am Bonuswert — kein großer Verlust, aber auch kein klarer Gewinn.",
          noteBad: "Die erwarteten Kosten für das Freispielen übersteigen den Bonuswert — statistisch lohnt es sich nicht, nur wegen des Bonus zu spielen.",
          useBtn: "Diesen Bonus berechnen", ctaBtn: "Zum Bonus", offersTitle: "Boni mit klaren Umsatzbedingungen" },
    it: { good: "Il bonus conviene", mid: "Al limite", bad: "Il bonus non conviene", perDay: "scommesse al giorno",
          noteGood: "Il valore atteso è positivo: statisticamente il bonus vale più di quanto costi sbloccarlo.",
          noteMid: "Il costo atteso è vicino al valore del bonus — non una grande perdita, ma nemmeno un vantaggio chiaro.",
          noteBad: "Il costo atteso per sbloccare il bonus supera il suo valore — statisticamente non conviene inseguirlo solo per il bonus.",
          useBtn: "Calcola questo bonus", ctaBtn: "Vai al bonus", offersTitle: "Bonus con condizioni di rollover chiare" },
    fr: { good: "Le bonus en vaut la peine", mid: "À la limite", bad: "Le bonus n'en vaut pas la peine", perDay: "mises par jour",
          noteGood: "La valeur attendue est positive : statistiquement, le bonus vaut plus que son coût de déblocage.",
          noteMid: "Le coût attendu est proche de la valeur du bonus — ni grosse perte, ni gain net.",
          noteBad: "Le coût attendu pour débloquer le bonus dépasse sa valeur — statistiquement inutile de le viser uniquement pour le bonus.",
          useBtn: "Calculer ce bonus", ctaBtn: "Voir le bonus", offersTitle: "Bonus avec des conditions de mise claires" },
    pt: { good: "O bônus compensa", mid: "No limite", bad: "O bônus não compensa", perDay: "apostas por dia",
          noteGood: "O valor esperado é positivo: estatisticamente o bônus vale mais do que custa liberá-lo.",
          noteMid: "O custo esperado está perto do valor do bônus — não é uma grande perda, mas também não é um ganho claro.",
          noteBad: "O custo esperado para liberar o bônus supera seu valor — estatisticamente não compensa correr atrás só pelo bônus.",
          useBtn: "Calcular este bônus", ctaBtn: "Ir para o bônus", offersTitle: "Bônus com termos de rollover claros" },
  };

  function lang() {
    var m = { es: "es", en: "en", de: "de", it: "it", fr: "fr", pt: "pt" };
    var l = (document.documentElement.lang || "en").split("-")[0];
    return m[l] || "en";
  }
  var T = VERDICTS[lang()] || VERDICTS.en;

  function fmt(n) {
    try { return new Intl.NumberFormat(LOCALE, { style: "currency", currency: CURRENCY, maximumFractionDigits: 0 }).format(n); }
    catch (e) { return String(Math.round(n)); }
  }

  function num(id) {
    var v = parseFloat(document.getElementById(id).value);
    return isNaN(v) ? 0 : v;
  }

  var base = "bonus"; // or "both"

  function calc() {
    var D = num("f-deposit");
    var p = num("f-pct");
    var maxEl = document.getElementById("f-max");
    var Bmax = maxEl.value === "" ? Infinity : num("f-max");
    var x = num("f-wager");
    var c = parseFloat(document.getElementById("f-game").value) || 1;
    var RTP = num("f-rtp");
    var days = num("f-days");

    var B = Math.min(D * p / 100, Bmax);
    var W = base === "both" ? (B + D) * x / c : B * x / c;
    var L = W * (1 - RTP / 100);
    var EV = B - L;

    document.getElementById("r-wagering").textContent = fmt(W);
    document.getElementById("r-bonus").textContent = fmt(B);
    document.getElementById("r-loss").textContent = fmt(L);
    document.getElementById("r-ev").textContent = (EV >= 0 ? "+" : "") + fmt(EV);

    var perDayRow = document.getElementById("r-perday-row");
    if (days > 0) {
      perDayRow.style.display = "";
      document.getElementById("r-perday").textContent = fmt(W / days) + " / " + days + "d";
    } else {
      perDayRow.style.display = "none";
    }

    var verdict = document.getElementById("r-verdict");
    var note = document.getElementById("r-verdict-note");
    verdict.classList.remove("good", "mid", "bad");
    var threshold = -0.2 * B;
    if (EV >= 0) {
      verdict.classList.add("good");
      verdict.firstChild.textContent = T.good;
      note.textContent = T.noteGood;
    } else if (EV >= threshold) {
      verdict.classList.add("mid");
      verdict.firstChild.textContent = T.mid;
      note.textContent = T.noteMid;
    } else {
      verdict.classList.add("bad");
      verdict.firstChild.textContent = T.bad;
      note.textContent = T.noteBad;
    }
  }

  function wireForm() {
    document.querySelectorAll(".calc-form input, .calc-form select").forEach(function (el) {
      el.addEventListener("input", calc);
    });
    document.getElementById("f-game").addEventListener("change", function () {
      var opt = this.options[this.selectedIndex];
      document.getElementById("f-rtp").value = opt.getAttribute("data-rtp") || 96;
      calc();
    });
    var btnBonus = document.getElementById("f-base-bonus");
    var btnBoth = document.getElementById("f-base-both");
    btnBonus.addEventListener("click", function () { base = "bonus"; btnBonus.classList.add("active"); btnBoth.classList.remove("active"); calc(); });
    btnBoth.addEventListener("click", function () { base = "both"; btnBoth.classList.add("active"); btnBonus.classList.remove("active"); calc(); });
  }

  function loadOffers() {
    var box = document.getElementById("calc-offers");
    if (!box) return;
    fetch("/assets/data/casinos.json").then(function (r) { return r.json(); }).then(function (casinos) {
      var pool = casinos.filter(function (c) { return c.verified && c.countries.indexOf(GEO) !== -1; }).slice(0, 3);
      if (pool.length === 0) return;
      var html = '<div class="calc-sub-row" style="border:none;padding-top:14px;"><span style="font-weight:700;color:var(--text);">' + T.offersTitle + "</span></div>";
      pool.forEach(function (c) {
        var bonus = (c.bonus && c.bonus[GEO]) || "";
        var href = (c.link && c.link[GEO]) || "#";
        html +=
          '<div class="calc-offer-card">' +
          '<div class="logo-box" style="width:40px;height:40px;' + (c.logo_box_style || "") + '">' + c.logo_html + "</div>" +
          '<div class="calc-offer-main"><div class="name">' + c.name + '</div><div class="bonus-text">' + bonus + "</div></div>" +
          '<div class="calc-offer-actions">' +
          '<button type="button" class="calc-use-btn">' + T.useBtn + "</button>" +
          '<a class="btn" style="padding:6px 10px;font-size:12px;" href="' + href + '" rel="sponsored nofollow" target="_blank">' + T.ctaBtn + "</a>" +
          "</div></div>";
      });
      box.innerHTML = html;
      // NOTE: casinos.json only stores each operator's bonus as free text
      // (copied from the live site), not structured %/max/wager/RTP values,
      // so this button cannot honestly prefill an operator's real terms
      // without inventing numbers. It focuses the deposit field instead;
      // wire it to real structured terms once that data exists per operator.
      box.querySelectorAll(".calc-use-btn").forEach(function (btn) {
        btn.addEventListener("click", function () {
          document.getElementById("f-deposit").scrollIntoView({ behavior: "smooth", block: "center" });
          document.getElementById("f-deposit").focus();
        });
      });
    }).catch(function () { /* offers are optional, calculator still works without them */ });
  }

  document.addEventListener("DOMContentLoaded", function () {
    if (!document.getElementById("f-deposit")) return;
    wireForm();
    loadOffers();
    calc();
  });
})();
