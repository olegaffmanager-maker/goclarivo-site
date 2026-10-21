/* GoClarivo casino-picker quiz (GoClarivo_plan.docx, section 1).
 * Pure client-side, no server. The question text and options live as plain
 * HTML on the page (same pattern as the rest of the site); this script only
 * drives step navigation, scores the already-published operator list in
 * assets/data/casinos.json, and renders the result cards.
 *
 * Scoring is intentionally conservative: casinos.json documents that only
 * the "bonus" score reflects a confirmed, operator-specific difference --
 * payout/games/mobile/beginner are neutral placeholders the same for every
 * operator (see each entry's _scores_note). So when the visitor says the
 * bonus is what matters most, operators are ranked by that confirmed bonus
 * score. For every other answer, the existing published order (the same
 * order the cards appear in above) is kept rather than inventing a
 * differentiator the data doesn't support.
 */
(function () {
  "use strict";

  var script = document.currentScript;
  var GEO = script.getAttribute("data-geo");
  var LOCALE = script.getAttribute("data-locale") || "en-US";

  var root = document.getElementById("quiz-card");
  if (!root) return;

  var STRINGS = {
    en: {
      bestMatch: "Best match",
      retake: "Retake quiz",
      seeAll: "See all compared casinos",
      resultsHeading: "Your matches",
      noResultsTitle: "No compared operator for your country yet",
      noResults: "We don't have a compared operator for your country in this quiz yet. Browse the full comparison below.",
      reasonBonus: "Scored highest here for bonus value.",
      reasonGeneric: "One of the operators we currently compare for your country.",
      cta: "Go to Casino",
      disclosure: "This uses the same comparison data as the list above. GoClarivo may earn a commission from these operators -- it does not affect which one is shown first. Full detail: ",
      disclosureLink: "editorial policy",
      disclosureHref: "/en/editorial-policy/"
    },
    es: {
      bestMatch: "Mejor opción",
      retake: "Repetir el quiz",
      seeAll: "Ver todos los casinos comparados",
      resultsHeading: "Tus resultados",
      noResultsTitle: "Todavía no hay un operador comparado para tu país",
      noResults: "Todavía no tenemos un operador comparado para tu país en este quiz. Explora la comparación completa a continuación.",
      reasonBonus: "El mejor puntuado aquí por el valor de su bono.",
      reasonGeneric: "Uno de los operadores que comparamos actualmente para tu país.",
      cta: "Ir al casino",
      disclosure: "Esto usa los mismos datos de comparación que la lista de arriba. GoClarivo puede recibir una comisión de estos operadores -- esto no influye en cuál se muestra primero. Más detalle: ",
      disclosureLink: "política editorial",
      disclosureHref: "/" + GEO + "/editorial-policy/"
    },
    de: {
      bestMatch: "Beste Übereinstimmung",
      retake: "Quiz wiederholen",
      seeAll: "Alle verglichenen Casinos ansehen",
      resultsHeading: "Deine Treffer",
      noResultsTitle: "Noch kein verglichener Anbieter für dein Land",
      noResults: "Für dein Land gibt es in diesem Quiz noch keinen verglichenen Anbieter. Sieh dir den vollständigen Vergleich unten an.",
      reasonBonus: "Hier am besten bewertet für den Bonuswert.",
      reasonGeneric: "Einer der Anbieter, die wir aktuell für dein Land vergleichen.",
      cta: "Zum Casino",
      disclosure: "Dies nutzt dieselben Vergleichsdaten wie die Liste oben. GoClarivo kann von diesen Anbietern eine Provision erhalten -- das beeinflusst nicht, welcher zuerst angezeigt wird. Details: ",
      disclosureLink: "redaktionelle Richtlinie",
      disclosureHref: "/de/editorial-policy/"
    },
    it: {
      bestMatch: "Il migliore per te",
      retake: "Rifai il quiz",
      seeAll: "Vedi tutti i casinò comparati",
      resultsHeading: "I tuoi risultati",
      noResultsTitle: "Ancora nessun operatore comparato per il tuo paese",
      noResults: "Per il tuo paese non abbiamo ancora un operatore comparato in questo quiz. Guarda il confronto completo qui sotto.",
      reasonBonus: "Il punteggio più alto qui per il valore del bonus.",
      reasonGeneric: "Uno degli operatori che confrontiamo attualmente per il tuo paese.",
      cta: "Vai al casinò",
      disclosure: "Questo usa gli stessi dati di confronto della lista sopra. GoClarivo potrebbe ricevere una commissione da questi operatori -- questo non influisce su quale viene mostrato per primo. Dettagli: ",
      disclosureLink: "policy editoriale",
      disclosureHref: "/it/editorial-policy/"
    },
    pt: {
      bestMatch: "Melhor opção",
      retake: "Refazer o quiz",
      seeAll: "Ver todos os casinos comparados",
      resultsHeading: "Os seus resultados",
      noResultsTitle: "Ainda não há um operador comparado para o seu país",
      noResults: "Ainda não temos um operador comparado para o seu país neste quiz. Veja a comparação completa abaixo.",
      reasonBonus: "O mais bem pontuado aqui pelo valor do bónus.",
      reasonGeneric: "Um dos operadores que comparamos atualmente para o seu país.",
      cta: "Ir para o casino",
      disclosure: "Isto usa os mesmos dados de comparação da lista acima. A GoClarivo pode receber uma comissão destes operadores -- isto não influencia qual é mostrado primeiro. Mais detalhe: ",
      disclosureLink: "política editorial",
      disclosureHref: "/pt/editorial-policy/"
    },
    fr: {
      bestMatch: "Meilleur choix",
      retake: "Refaire le quiz",
      seeAll: "Voir tous les casinos comparés",
      resultsHeading: "Vos résultats",
      noResultsTitle: "Pas encore d'opérateur comparé pour votre pays",
      noResults: "Nous n'avons pas encore d'opérateur comparé pour votre pays dans ce quiz. Consultez la comparaison complète ci-dessous.",
      reasonBonus: "Le mieux noté ici pour la valeur du bonus.",
      reasonGeneric: "L'un des opérateurs que nous comparons actuellement pour votre pays.",
      cta: "Aller au casino",
      disclosure: "Ceci utilise les mêmes données de comparaison que la liste ci-dessus. GoClarivo peut recevoir une commission de ces opérateurs -- cela n'influence pas lequel est affiché en premier. Détails : ",
      disclosureLink: "politique éditoriale",
      disclosureHref: "/bf/editorial-policy/"
    }
  };

  function lang() {
    var m = { es: "es", en: "en", de: "de", it: "it", fr: "fr", pt: "pt" };
    var l = (document.documentElement.lang || "en").split("-")[0];
    return m[l] || "en";
  }
  var T = STRINGS[lang()] || STRINGS.en;

  function track(name, params) {
    try {
      if (typeof window.gtag === "function") {
        window.gtag("event", name, params || {});
      }
      document.dispatchEvent(new CustomEvent("goclarivo:" + name, { detail: params || {} }));
    } catch (e) { /* analytics are optional */ }
  }

  var answers = {};
  var started = false;
  var steps = root.querySelectorAll(".quiz-step[data-step]");
  var progressBar = root.querySelector(".quiz-progress-bar");

  function showStep(n) {
    steps.forEach(function (el) {
      el.hidden = el.getAttribute("data-step") !== String(n);
    });
    if (progressBar) {
      var pct = n === "result" ? 100 : Math.round((Number(n) / 3) * 100);
      progressBar.style.width = pct + "%";
    }
    var heading = root.querySelector('.quiz-step[data-step="' + n + '"] h2');
    if (heading) {
      heading.setAttribute("tabindex", "-1");
      heading.focus({ preventScroll: true });
    }
  }

  function pickCasinos() {
    fetch("/assets/data/casinos.json")
      .then(function (r) { return r.json(); })
      .then(function (casinos) {
        var pool = casinos.filter(function (c) {
          return c.verified && c.countries.indexOf(GEO) !== -1 && c.link && c.link[GEO];
        });
        if (answers.priority === "bonus") {
          pool = pool.slice().sort(function (a, b) {
            return (b.scores && b.scores.bonus || 0) - (a.scores && a.scores.bonus || 0);
          });
        }
        renderResults(pool.slice(0, 3));
        track("quiz_complete", answers);
      })
      .catch(function () { renderResults([]); });
  }

  function esc(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }

  function renderResults(list) {
    var box = document.getElementById("quiz-results");
    if (!box) return;
    if (!list.length) {
      box.innerHTML =
        '<div class="review-panel"><b>' + esc(T.noResultsTitle) + "</b><p>" + esc(T.noResults) + "</p></div>" +
        '<div class="quiz-result-actions"><a class="btn btn-ghost" href="#top-list">' + esc(T.seeAll) + "</a>" +
        '<button type="button" class="btn-ghost quiz-retake" id="quiz-retake">' + esc(T.retake) + "</button></div>";
      wireRetake();
      return;
    }
    var html = '<div class="sec-head" style="margin-bottom:20px;"><h2>' + esc(T.resultsHeading) + "</h2></div>";
    list.forEach(function (c, i) {
      var reason = answers.priority === "bonus" ? T.reasonBonus : T.reasonGeneric;
      var bonusText = (c.bonus && c.bonus[GEO]) || "";
      html +=
        '<div class="casino-card quiz-result-card">' +
          '<div class="logo-box" style="' + (c.logo_box_style || "") + '">' + (c.logo_html || "") + "</div>" +
          '<div class="casino-main">' +
            '<div class="top-row"><span class="name">' + esc(c.name) + "</span>" +
            (i === 0 ? '<span class="verify-badge verify-green">' + esc(T.bestMatch) + "</span>" : "") +
            "</div>" +
            (bonusText ? '<div class="bonus-text">' + bonusText + "</div>" : "") +
            '<p class="quiz-reason">' + esc(reason) + "</p>" +
          "</div>" +
          '<div class="casino-cta"><a class="btn" href="' + esc(c.link[GEO]) + '" rel="sponsored nofollow noopener" target="_blank" data-quiz-click="' + esc(c.id) + '">' + esc(T.cta) + "</a></div>" +
        "</div>";
    });
    html +=
      '<p class="quiz-disclosure">' + esc(T.disclosure) + '<a href="' + esc(T.disclosureHref) + '">' + esc(T.disclosureLink) + "</a></p>" +
      '<div class="quiz-result-actions"><a class="btn btn-ghost" href="#top-list">' + esc(T.seeAll) + "</a>" +
      '<button type="button" class="btn-ghost quiz-retake" id="quiz-retake">' + esc(T.retake) + "</button></div>";
    box.innerHTML = html;
    wireRetake();
    box.querySelectorAll("[data-quiz-click]").forEach(function (a) {
      a.addEventListener("click", function () {
        track("quiz_click", { id: a.getAttribute("data-quiz-click"), position: Array.prototype.indexOf.call(box.querySelectorAll("[data-quiz-click]"), a) + 1 });
      });
    });
  }

  function wireRetake() {
    var btn = document.getElementById("quiz-retake");
    if (!btn) return;
    btn.addEventListener("click", function () {
      answers = {};
      started = false;
      showStep("1");
    });
  }

  root.addEventListener("click", function (e) {
    var opt = e.target.closest(".quiz-opt");
    if (opt) {
      if (!started) { started = true; track("quiz_start", {}); }
      var q = opt.getAttribute("data-q");
      var v = opt.getAttribute("data-v");
      answers[q] = v;
      track("quiz_step", { question: q, answer: v });
      if (q === "priority") showStep("2");
      else if (q === "device") showStep("3");
      else if (q === "experience") {
        showStep("result");
        pickCasinos();
      }
      return;
    }
    var back = e.target.closest(".quiz-back");
    if (back) {
      showStep(back.getAttribute("data-back"));
    }
  });
})();
