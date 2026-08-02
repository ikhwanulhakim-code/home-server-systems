const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

if (!reducedMotion) {
  requestAnimationFrame(() => {
    document.querySelectorAll("[data-request-path]").forEach((path) => {
      path.dataset.active = "true";
    });
  });
}
