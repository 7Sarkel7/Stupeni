// @ts-check
const owner = '7Sarkel7';
const repo = 'Stupeni';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Ступени: глубокий режим',
  tagline: 'Длинные главы, практика в Android Studio и официальные доки',
  favicon: 'img/favicon.png',
  url: `https://${owner.toLowerCase()}.github.io`,
  baseUrl: `/${repo}/`,
  organizationName: owner,
  projectName: repo,
  onBrokenLinks: 'throw',
  markdown: {
    hooks: {onBrokenMarkdownLinks: 'throw'},
  },
  i18n: {defaultLocale: 'ru', locales: ['ru']},
  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          path: '../content/deep',
          routeBasePath: '/',
          sidebarPath: './sidebars.js',
          editUrl: `https://github.com/${owner}/${repo}/edit/main/content/deep/`,
          exclude: ['**/_*.md', '**/_*/**'],
        },
        blog: false,
        theme: {customCss: './src/css/custom.css'},
      }),
    ],
  ],
  themes: [
    [
      '@easyops-cn/docusaurus-search-local',
      {
        hashed: true,
        language: ['ru', 'en'],
        docsRouteBasePath: '/',
        docsDir: '../content/deep',
        indexBlog: false,
      },
    ],
  ],
  themeConfig: {
    colorMode: {respectPrefersColorScheme: true},
    navbar: {
      title: 'Ступени',
      items: [
        {type: 'docSidebar', sidebarId: 'deep', position: 'left', label: 'Главы'},
        {href: `https://github.com/${owner}/${repo}`, label: 'GitHub', position: 'right'},
      ],
    },
    footer: {style: 'dark', copyright: 'Ступени — учебный проект. Прогресс хранится только в вашем браузере.'},
    prism: {additionalLanguages: ['kotlin', 'bash', 'json', 'gradle']},
  },
};

module.exports = config;
