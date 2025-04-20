import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Teisu",
  description: "A reactive library for Luau",
  srcDir: './src',
  base: "/teisu/",
  cleanUrls: true,

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config

    footer: {
      message: 'Released under the MIT License.',
    },

    search: {
      provider: "local"
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
          ]
        },

        {
          text: "Fundamentals",
          items: [
            { text: "Flecs", link: "/tutorials/fundamentals/flecs" },
            { text: "Effects", link: "/tutorials/fundamentals/effects" },
            { text: "Observers", link: "/tutorials/fundamentals/observers" },
            { text: "Computeds", link: "/tutorials/fundamentals/computeds" },
            { text: "Molecules", link: "/tutorials/fundamentals/molecules" },
          ]
        },

        {
          text: "Transformers",
          items: [
            { text: "Mapped", link: "/tutorials/transformers/mapped" },
          ],
        },

        {
          text: "Animation",
          items: [
            { text: "Springs", link: "/tutorials/animation/springs" },
          ],
        },

        {
          text: "UI",
          items: [
            { text: "Element Creation", link: "/tutorials/instances/element-creation" },
            { text: "Actions", link: "/tutorials/instances/actions" },
            { text: "Components", link: "/tutorials/instances/components" },
            { text: "Cleanup", link: "/tutorials/instances/cleanup" },
            { text: "Show", link: "/tutorials/instances/show" },
            { text: "Switch", link: "/tutorials/instances/switch" },
          ],
        },

        {
          text: "Networking",
          items: [
            { text: "Server-Client Sync", link: "/tutorials/networking" },
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
