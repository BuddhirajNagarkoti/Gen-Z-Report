// GSAP Scroll Animations
gsap.registerPlugin(ScrollTrigger);

// Hero Animations
gsap.from(".hero-content h1", {
    y: 100,
    opacity: 0,
    duration: 1.5,
    ease: "power4.out",
    delay: 0.5
});

gsap.from(".hero-content p", {
    y: 50,
    opacity: 0,
    duration: 1.2,
    ease: "power2.out",
    delay: 1
});

gsap.from(".hero-actions", {
    y: 30,
    opacity: 0,
    duration: 1,
    ease: "power2.out",
    delay: 1.3
});

// Stats Counter Logic
const stats = [
    { id: 'stat-deaths', end: 76 },
    { id: 'stat-injuries', end: 2522 },
    { id: 'stat-damage', end: 85 },
    { id: 'stat-districts', end: 7 }
];

const startCounters = () => {
    stats.forEach(stat => {
        const element = document.getElementById(stat.id);
        if (element) {
            const countUp = new countUp.CountUp(stat.id, stat.end, {
                duration: 2.5,
                useEasing: true,
                useGrouping: true,
                separator: ',',
                decimal: '.',
            });
            if (!countUp.error) {
                countUp.start();
            } else {
                console.error(countUp.error);
            }
        }
    });
};

// Start counters when summary section is reached
ScrollTrigger.create({
    trigger: "#summary",
    start: "top 80%",
    onEnter: startCounters,
    once: true
});

// Card Animations
gsap.utils.toArray(".bento-item").forEach(card => {
    gsap.from(card, {
        scrollTrigger: {
            trigger: card,
            start: "top 90%",
            toggleActions: "play none none none"
        },
        y: 60,
        opacity: 0,
        duration: 1,
        ease: "power3.out"
    });
});

gsap.utils.toArray(".feature-card").forEach(card => {
    gsap.from(card, {
        scrollTrigger: {
            trigger: card,
            start: "top 90%",
            toggleActions: "play none none none"
        },
        scale: 0.9,
        opacity: 0,
        duration: 0.8,
        ease: "back.out(1.7)"
    });
});

// Timeline Animations
gsap.utils.toArray(".timeline-item").forEach(item => {
    gsap.from(item.querySelector(".content"), {
        scrollTrigger: {
            trigger: item,
            start: "top 80%",
            toggleActions: "play none none none"
        },
        x: 100,
        opacity: 0,
        duration: 1.2,
        ease: "power4.out"
    });
});

// Recom List Animations
gsap.from(".recom-list li", {
    scrollTrigger: {
        trigger: ".recom-list",
        start: "top 80%",
        toggleActions: "play none none none"
    },
    x: -50,
    opacity: 0,
    stagger: 0.2,
    duration: 1,
    ease: "power2.out"
});

// Glitch Effect logic (optional, for the text)
const glitchTitle = document.querySelector('.glitch');
if (glitchTitle) {
    setInterval(() => {
        glitchTitle.classList.add('active');
        setTimeout(() => glitchTitle.classList.remove('active'), 200);
    }, 3000);
}
