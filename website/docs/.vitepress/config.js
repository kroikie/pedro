export default {
  title: 'Pedro',
  description: 'Multiplayer Card Game Documentation',
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'How to Play', link: '/rules' },
    ],
    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'Introduction', link: '/' },
          { text: 'Rules', link: '/rules' },
        ]
      }
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/ool/pedro' }
    ]
  }
}
