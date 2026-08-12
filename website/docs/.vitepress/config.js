export default {
  title: 'Pedro',
  description: 'The Ultimate Pedro Multiplayer Card Game Player Guide',
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Game Overview', link: '/overview' },
      { text: 'How to Play', link: '/rules' },
    ],
    sidebar: [
      {
        text: 'Player Guide',
        items: [
          { text: 'Welcome', link: '/' },
          { text: 'Game Overview', link: '/overview' },
          { text: 'How to Play', link: '/rules' },
        ]
      }
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/ool/pedro' }
    ]
  }
}
