document.addEventListener('DOMContentLoaded', () => {
  // Theme toggle logic
  const themeToggle = document.getElementById('toggle-theme');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  let dark = localStorage.getItem('theme')
    ? localStorage.getItem('theme') === 'dark'
    : prefersDark;

  function setTheme(isDark) {
    document.body.classList.toggle('dark', isDark);
    themeToggle.textContent = isDark ? 'dark_mode' : 'light_mode';
    localStorage.setItem('theme', isDark ? 'dark' : 'light');
  }

  setTheme(dark);

  themeToggle.addEventListener('click', () => {
    dark = !dark;
    setTheme(dark);
  });

  // Traduções
  const translations = {
    EN: {
      title: "Mosaico",
      subtitle: "Portuguese Tile Puzzle Game!",
      download_btn: "Download now for Android",
      main_features: "Main features:",
      feature_puzzles: "<b>Portuguese Tile Collections:</b> Discover beautiful puzzles featuring traditional Portuguese azulejos (tiles) with different difficulty levels from 4x4 to 5x5 grids.",
      feature_timing: "<b>Time Challenge:</b> Test your speed and compete for the best completion times. Each puzzle tracks your performance!",
      feature_ranking: "<b>Global Ranking:</b> Compete with players worldwide! See where you stand on the leaderboard and challenge yourself to reach the top.",
      feature_auth: "<b>Google Sign-In:</b> Save your progress, sync across devices, and track your achievements with Google authentication.",
      feature_theme: "<b>Dark and Light Mode:</b> Choose the theme that best suits your style or let the app follow your system theme.",
      feature_multilingual: "<b>Multilingual Support:</b> Available in Portuguese and English, with easy language switching.",
      feature_sound: "<b>Sound Effects:</b> Enjoy satisfying sound feedback as you place each tile piece, or play in silent mode.",
      feature_celebration: "<b>Victory Celebrations:</b> Complete a puzzle and enjoy beautiful firework animations celebrating your achievement!",
      cta_title: "Perfect for puzzle enthusiasts, Portuguese Tiles lovers, and relaxation!",
      cta_footer: "Discover Portuguese azulejos, challenge yourself, and have fun with Mosaico!",
      soon_ios: "Soon for iOS",
      intro: `Challenge your mind with <b>Mosaico</b>, a unique puzzle game featuring beautiful Portuguese azulejos (traditional tiles)! Arrange colorful tile pieces to recreate stunning Portuguese ceramic art. Perfect for puzzle lovers and Portuguese Tiles enthusiasts of all ages.`,
      seo: {
        description: "Mosaico - Portuguese tile puzzle game! Solve beautiful azulejo puzzles, discover Portuguese culture, compete for best times, and climb the global ranking.",
        keywords: "Mosaico, Portuguese tiles, azulejos, puzzle game, Portuguese culture, brain training, Android game, tile puzzle, azulejos portugueses",
        "og:title": "Mosaico – Portuguese Tile Puzzle Game!",
        "og:description": "Mosaico - Portuguese tile puzzle game! Solve beautiful azulejo puzzles, discover Portuguese culture, compete for best times, and climb the global ranking.",
        "twitter:title": "Mosaico – Portuguese Tile Puzzle Game!",
        "twitter:description": "Mosaico - Portuguese tile puzzle game! Solve beautiful azulejo puzzles, discover Portuguese culture, compete for best times, and climb the global ranking."
      }
    },
    PT: {
      title: "Mosaico",
      subtitle: "Jogo de Puzzles de Azulejos!",
      download_btn: "Descarregar para Android",
      main_features: "Principais funcionalidades:",
      feature_puzzles: "<b>Coleções de Azulejos Portugueses:</b> Descubra belos puzzles com azulejos tradicionais portugueses, com diferentes níveis de dificuldade de 4x4 a 5x5.",
      feature_timing: "<b>Desafio de Tempo:</b> Teste a sua velocidade e compita pelos melhores tempos de conclusão. Cada puzzle regista o seu desempenho!",
      feature_ranking: "<b>Ranking Global:</b> Compita com jogadores de todo o mundo! Veja a sua posição no ranking e desafie-se a chegar ao topo.",
      feature_auth: "<b>Login Google:</b> Guarde o seu progresso, sincronize entre dispositivos e acompanhe as suas conquistas com autenticação Google.",
      feature_theme: "<b>Modo Escuro e Claro:</b> Escolha o tema que mais combina consigo ou deixe a app seguir o tema do sistema.",
      feature_multilingual: "<b>Suporte Multilíngue:</b> Disponível em Português e Inglês, com fácil alternância de idioma.",
      feature_sound: "<b>Efeitos Sonoros:</b> Desfrute de feedback sonoro satisfatório ao colocar cada peça de azulejo, ou jogue em modo silencioso.",
      feature_celebration: "<b>Celebrações de Vitória:</b> Complete um puzzle e desfrute de belas animações de fogo de artifício celebrando a sua conquista!",
      cta_title: "Perfeito para entusiastas de puzzles, amantes da cultura portuguesa e relaxamento!",
      cta_footer: "Descubra os azulejos portugueses, desafie-se e divirta-se com o Mosaico!",
      soon_ios: "Em breve para iOS",
      intro: `Desafie a sua mente com <b>Mosaico</b>, um jogo de puzzles único com belos azulejos portugueses tradicionais! Organize peças de azulejos coloridos para recriar a deslumbrante arte cerâmica portuguesa. Perfeito para amantes de puzzles e de azulejos portugueses de todas as idades.`,
      seo: {
        description: "Mosaico - jogo de puzzles de azulejos portugueses! Resolva belos puzzles de azulejos, descubra a cultura portuguesa, compita pelos melhores tempos e suba no ranking global.",
        keywords: "Mosaico, azulejos portugueses, azulejos, jogo de puzzles, cultura portuguesa, treino cerebral, jogo Android, puzzle azulejos, Portuguese tiles",
        "og:title": "Mosaico – Jogo de Puzzles de Azulejos!",
        "og:description": "Mosaico - jogo de puzzles de azulejos portugueses! Resolva belos puzzles de azulejos, descubra a cultura portuguesa, compita pelos melhores tempos e suba no ranking global.",
        "twitter:title": "Mosaico – Jogo de Puzzles de Azulejos!",
        "twitter:description": "Mosaico - jogo de puzzles de azulejos portugueses! Resolva belos puzzles de azulejos, descubra a cultura portuguesa, compita pelos melhores tempos e suba no ranking global."
      }
    }
  };

  function setLanguage(lang) {
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      if (translations[lang] && translations[lang][key]) {
        if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
          el.placeholder = translations[lang][key];
        } else {
          el.innerHTML = translations[lang][key];
        }
      }
    });
    // SEO meta tags
    if (translations[lang] && translations[lang].seo) {
      document.querySelectorAll('[data-i18n-seo]').forEach(meta => {
        const key = meta.getAttribute('data-i18n-seo');
        if (translations[lang].seo[key]) {
          if (meta.hasAttribute('content')) {
            meta.setAttribute('content', translations[lang].seo[key]);
          }
        }
      });
      // Atualiza o <title>
      if (lang === 'PT') {
        document.title = "Mosaico – Jogo de Puzzles de Azulejos Portugueses";
      } else {
        document.title = "Mosaico – Portuguese Tile Puzzle Game";
      }
    }
    localStorage.setItem('lang', lang);
  }

  // Language menu logic
  const langBtn = document.getElementById('toggle-lang');
  const langMenu = document.getElementById('lang-menu');
  let currentLang = localStorage.getItem('lang') || 'EN';
  if (langBtn && langMenu) {
    langBtn.textContent = currentLang;
    setLanguage(currentLang);

    langBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      langMenu.style.display = langMenu.style.display === 'block' ? 'none' : 'block';
    });
    langMenu.querySelectorAll('.lang-option').forEach(option => {
      option.addEventListener('click', (e) => {
        const lang = option.getAttribute('data-lang');
        langBtn.textContent = lang;
        langMenu.style.display = 'none';
        currentLang = lang;
        setLanguage(lang);
      });
    });
    document.addEventListener('click', () => {
      langMenu.style.display = 'none';
    });
    langMenu.addEventListener('click', e => e.stopPropagation());
  } else {
    setLanguage(currentLang);
  }

  // Carousel logic
  const slides = document.querySelectorAll('.carousel-slide');
  const prevBtn = document.querySelector('.carousel-btn.prev');
  const nextBtn = document.querySelector('.carousel-btn.next');
  const dots = document.querySelectorAll('.carousel-dots .dot');
  let currentSlide = 0;
  let carouselInterval;

  function showSlide(idx) {
    slides.forEach((slide, i) => {
      slide.classList.toggle('active', i === idx);
      if (dots[i]) dots[i].classList.toggle('active', i === idx);
    });
    currentSlide = idx;
  }

  function nextSlide() {
    showSlide((currentSlide + 1) % slides.length);
  }

  function prevSlide() {
    showSlide((currentSlide - 1 + slides.length) % slides.length);
  }

  if (prevBtn && nextBtn && slides.length > 0) {
    prevBtn.addEventListener('click', () => {
      prevSlide();
      resetCarouselInterval();
    });
    nextBtn.addEventListener('click', () => {
      nextSlide();
      resetCarouselInterval();
    });
    dots.forEach((dot, idx) => {
      dot.addEventListener('click', () => {
        showSlide(idx);
        resetCarouselInterval();
      });
    });
    function resetCarouselInterval() {
      clearInterval(carouselInterval);
      carouselInterval = setInterval(nextSlide, 5000);
    }
    carouselInterval = setInterval(nextSlide, 5000);
    showSlide(0);
  }
});
