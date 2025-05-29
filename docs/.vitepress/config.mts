import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Teisu",
  description: "A reactive library for Luau",
  base: "/teisu/",
  cleanUrls: true,
  
  markdown: {
    config(md) {
      md.use(tabsMarkdownPlugin)
    }
  },

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
      { text: "API", link: "/api/teisu" },
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
            { text: "Molecules", link: "/tutorials/fundamentals/molecules" },
            { text: "Derivable", link: "/tutorials/fundamentals/derivable" },
            { text: "Scopes", link: "/tutorials/fundamentals/scopes" }, 
            { text: "Cleanup", link: "/tutorials/fundamentals/cleanup" },
            { text: "Strict Mode", link: "/tutorials/fundamentals/strict-mode" },
          ]
        },

        {
          text: "Tables",
          items: [
            { text: "Values", link: "/tutorials/tables/values" },
            { text: "Indexes", link: "/tutorials/tables/indexes" },
            { text: "Keys", link: "/tutorials/tables/keys" },
            { text: "When should I use...", link: "/tutorials/tables/when-should-i-use-what" },
          ],
        },

        {
          text: "Animation",
          items: [
            { text: "Springs", link: "/tutorials/animation/springs" },
            { text: "Tweens", link: "/tutorials/animation/tweens" },
          ],
        },

        {
          text: "UI",
          items: [
            { text: "Element Creation", link: "/tutorials/instances/element-creation" },
            { text: "Actions", link: "/tutorials/instances/actions" },
            { text: "Components", link: "/tutorials/instances/components" },
            { text: "Show", link: "/tutorials/instances/show" },
            { text: "Switch", link: "/tutorials/instances/switch" },
          ],
        },

        {
          text: "Advanced",
          items: [
            { text: "Context", link: "/tutorials/advanced/context" },
          ],
        },

        {
          text: "Networking",
          items: [
            { text: "Server-Client Sync", link: "/tutorials/networking" },
          ],
        },
      ],

      "/api/": [
        {
          text: "API Reference",
          items: [
            { text: "Teisu", link: "/api/teisu" },
            { text: "Reactivity: Core", link: "/api/reactivity-core" },
            { text: "Reactivity: Observers", link: "/api/reactivity-observers" },
            { text: "Reactivity: Tables", link: "/api/reactivity-tables" },
            { text: "Reactivity: Utility", link: "/api/reactivity-utility" },
            { text: "Reactivity: Conditions", link: "/api/reactivity-conditions" },
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
