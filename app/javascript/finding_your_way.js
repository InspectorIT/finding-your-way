(function () {
    function initializeFindingYourWay() {
        // --- 1. Плавный скролл по кнопкам ---
        const scrollButtons = document.querySelectorAll("[data-scroll-to]");
        const mobileMenu = document.querySelector("[data-mobile-menu]");
        const menuToggle = document.querySelector("[data-menu-toggle]");
        const sections = document.querySelectorAll("main section[id]");
        const navLinks = document.querySelectorAll(".nav-link");

        scrollButtons.forEach(function (button) {
            if (button.dataset.findingWayBound === "true") return;
            button.dataset.findingWayBound = "true";

            button.addEventListener("click", function () {
                const target = document.getElementById(button.dataset.scrollTo);

                if (target) {
                    target.scrollIntoView({
                        behavior: "smooth",
                        block: "start"
                    });
                }

                if (mobileMenu) {
                    mobileMenu.classList.remove("is-open");
                }

                if (menuToggle) {
                    menuToggle.setAttribute("aria-expanded", "false");
                }
            });
        });

        // --- 2. Мобильное меню ---
        if (
            menuToggle &&
            mobileMenu &&
            menuToggle.dataset.findingWayBound !== "true"
        ) {
            menuToggle.dataset.findingWayBound = "true";

            menuToggle.addEventListener("click", function () {
                const isOpen = mobileMenu.classList.toggle("is-open");
                menuToggle.setAttribute("aria-expanded", String(isOpen));
            });
        }

        // --- 3. Подсветка активных секций ---
        if (sections.length > 0) {
            const observer = new IntersectionObserver(
                function (entries) {
                    entries.forEach(function (entry) {
                        if (!entry.isIntersecting) return;

                        navLinks.forEach(function (link) {
                            link.classList.toggle(
                                "active",
                                link.dataset.scrollTo === entry.target.id
                            );
                        });
                    });
                },
                { rootMargin: "-20% 0px -65% 0px" }
            );

            sections.forEach(function (section) {
                observer.observe(section);
            });
        }

        // --- 4. Копирование текста ---
        document.querySelectorAll("[data-copy-target]").forEach(function (button) {
            if (button.dataset.findingWayBound === "true") return;
            button.dataset.findingWayBound = "true";

            button.addEventListener("click", async function () {
                const target = document.getElementById(button.dataset.copyTarget);
                if (!target) return;

                const text = target.value || target.textContent || "";

                try {
                    await navigator.clipboard.writeText(text);

                    const originalText = button.textContent;
                    button.textContent = "Скопировано";
                    button.classList.add("copied");

                    window.setTimeout(function () {
                        button.textContent = originalText;
                        button.classList.remove("copied");
                    }, 1800);
                } catch (error) {
                    button.textContent = "Не удалось скопировать";

                    window.setTimeout(function () {
                        button.textContent = "Копировать";
                    }, 1800);
                }
            });
        });

        // --- 5. Модальные окна: закрытие по клику на серый фон (Backdrop) ---
        const modals = document.querySelectorAll("dialog");
        modals.forEach(function (modal) {
            if (modal.dataset.findingWayBound === "true") return;
            modal.dataset.findingWayBound = "true";

            modal.addEventListener("click", function (e) {
                const dialogDimensions = modal.getBoundingClientRect();
                if (
                    e.clientX < dialogDimensions.left ||
                    e.clientX > dialogDimensions.right ||
                    e.clientY < dialogDimensions.top ||
                    e.clientY > dialogDimensions.bottom
                ) {
                    modal.close();
                }
            });
        });
    }

    // --- 6. Глобальное закрытие выпадающего меню профиля при клике мимо ---
    document.addEventListener("click", function (event) {
        if (!event.target.closest(".user-dropdown")) {
            const dropdowns = document.getElementsByClassName("dropdown-content");
            for (let i = 0; i < dropdowns.length; i++) {
                dropdowns[i].classList.remove("show");
            }
        }
    });

    // В Rails Turbo событие turbo:load вызывается и при первой загрузке, и при переходах
    document.addEventListener("turbo:load", initializeFindingYourWay);
})();