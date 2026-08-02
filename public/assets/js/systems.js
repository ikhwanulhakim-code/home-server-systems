document.documentElement.classList.add("has-js");

document.addEventListener("DOMContentLoaded", () => {
  const sections = document.querySelectorAll(".reveal");
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  if (reducedMotion || !("IntersectionObserver" in window)) {
    sections.forEach((section) => section.classList.add("is-visible"));
    return;
  }

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;

        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    },
    { rootMargin: "0px 0px -8%", threshold: 0.08 }
  );

  // Hide the sections only once the observer exists to reveal them again.
  sections.forEach((section) => {
    section.classList.add("is-armed");
    observer.observe(section);
  });
});
