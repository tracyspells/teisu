import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Teisu",
  description: "A reactive library for Luau.",
  srcDir: './src',
  base: "/teisu/",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config

    footer: {
      message: 'Released under the MIT License.',
    },
  
    nav: [
      { text: 'Home', link: '/' },
      { text: "Quick Start", link: "/quick-start" },
      { text: 'API', link: '/api/reactivity-core' }
    ],

    sidebar: {

      "/quick-start/": [
        {
          text: "Quick Start",
          items: [
            { text: "Installation", link: "/quick-start" },
            { text: "Why Teisu?", link: "/quick-start/why-teisu" },
          ]
        },
      ],

      "/api/": [
        {
          text: "API Reference",
          items: [
            { text: "Reactivity: Core", link: "/api/reactivity-core" },
            { text: "Reactivity: Observers", link: "/api/reactivity-observers" },
            { text: "Reactivity: Utility", link: "/api/reactivity-utility" },
            { text: "Reactivity: Dynamic", link: "/api/reactivity-dynamic" },
            { text: "Element Creation", link: "/api/element-creation" },
            { text: "Animation", link: "/api/animation" },
            { text: "Networking", link: "/api/networking" },
          ]
        }
      ],

    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/vuejs/vitepress' }
    ]
  }
})
