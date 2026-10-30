import type { Directive } from 'vue'

const observer = new IntersectionObserver(
  (entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible')
        observer.unobserve(entry.target)
      }
    }
  },
  { threshold: 0.12, rootMargin: '0px 0px -48px 0px' },
)

/**
 * v-reveal — Apple-style scroll reveal.
 * Usage: v-reveal or v-reveal="120" (delay in ms)
 */
export const reveal: Directive<HTMLElement, number | undefined> = {
  mounted(el, binding) {
    el.classList.add('reveal')
    if (typeof binding.value === 'number') {
      el.style.setProperty('--reveal-delay', `${binding.value}ms`)
    }
    observer.observe(el)
  },
  unmounted(el) {
    observer.unobserve(el)
  },
}
