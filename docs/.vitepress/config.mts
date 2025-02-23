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
      { text: "Home", link: "/" },
      { text: "Tutorials", link: "/tutorials/getting-started" },
      { text: "API", link: "/api/reactivity-core" },
    ],

    sidebar: {

      "/tutorials/": [
        {
          text: "Getting Started",
          items: [
            { text: "Installation", link: "/tutorials/getting-started" },
            { text: "Why Teisu?", link: "/tutorials/getting-started/why-teisu" },
          ]
        },

        {
          text: "Fundamentals",
          items: [
            { text: "Flecs", link: "/tutorials/fundamentals/flecs" },
            { text: "Effects", link: "/tutorials/fundamentals/effects" },
            { text: "Observers", link: "/tutorials/fundamentals/observers" },
            { text: "Computeds", link: "/tutorials/fundamentals/computeds" },
          ]
        },

        {
          text: "UI",
          items: [
            { text: "Actions", link: "/tutorials/instances/actions" },
            { text: "Detect Property Changes", link: "/tutorials/instances/property-changes" },
          ],
        }
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
      { icon: 'github', link: 'https://github.com/tracyspells/teisu' }
    ]
  }
})
