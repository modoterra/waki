#!/usr/bin/env bash
# Waki webapp catalog: seed data and query helpers

waki_catalog_seed() {
  sqlite3 "$WAKI_DB_PATH" << 'SQL'
INSERT OR IGNORE INTO waki_webapps (name, url, icon_slug, category) VALUES

-- AI
('ChatGPT',       'https://chatgpt.com',             'chatgpt',           'ai'),
('Claude',        'https://claude.ai',               'claude-ai',         'ai'),
('Gemini',        'https://gemini.google.com',        'google-gemini',     'ai'),
('Perplexity',    'https://perplexity.ai',            'perplexity',        'ai'),
('Grok',          'https://grok.com',                 'grok',              'ai'),
('Copilot',       'https://copilot.microsoft.com',    'microsoft-copilot', 'ai'),
('Hugging Face',  'https://huggingface.co',           'hugging-face',      'ai'),
('DeepSeek',      'https://chat.deepseek.com',        'deepseek',          'ai'),

-- Cloud
('Cloudflare',    'https://dash.cloudflare.com',      'cloudflare',        'cloud'),
('AWS Console',   'https://console.aws.amazon.com',   'aws',               'cloud'),
('Google Cloud',  'https://console.cloud.google.com', 'google-cloud',      'cloud'),
('Azure',         'https://portal.azure.com',         'azure',             'cloud'),
('Vercel',        'https://vercel.com/dashboard',     'vercel',            'cloud'),
('Netlify',       'https://app.netlify.com',          'netlify',           'cloud'),
('DigitalOcean',  'https://cloud.digitalocean.com',   'digitalocean',      'cloud'),
('Hetzner',       'https://console.hetzner.cloud',    'hetzner',           'cloud'),
('Railway',       'https://railway.app/dashboard',    'railway',           'cloud'),
('Fly.io',        'https://fly.io/dashboard',         'fly-io',            'cloud'),
('Render',        'https://dashboard.render.com',     'render',            'cloud'),
('Linode',        'https://cloud.linode.com',         'linode',            'cloud'),

-- Communication
('Discord',          'https://discord.com/app',           'discord',          'communication'),
('Slack',            'https://app.slack.com',             'slack',            'communication'),
('WhatsApp',         'https://web.whatsapp.com',          'whatsapp',         'communication'),
('Telegram',         'https://web.telegram.org',          'telegram',         'communication'),
('Microsoft Teams',  'https://teams.microsoft.com',       'microsoft-teams',  'communication'),
('Zoom',             'https://app.zoom.us',               'zoom',             'communication'),
('Element',          'https://app.element.io',            'element',          'communication'),
('Google Chat',      'https://chat.google.com',           'google-chat',      'communication'),
('Skype',            'https://web.skype.com',             'skype',            'communication'),

-- Design
('Figma',       'https://figma.com',        'figma',      'design'),
('Canva',       'https://canva.com',        'canva',      'design'),
('Miro',        'https://miro.com',         'miro',       'design'),
('Excalidraw',  'https://excalidraw.com',   'excalidraw', 'design'),

-- Development
('GitHub',          'https://github.com',           'github',        'development'),
('GitLab',          'https://gitlab.com',           'gitlab',        'development'),
('Bitbucket',       'https://bitbucket.org',        'bitbucket',     'development'),
('Docker Hub',      'https://hub.docker.com',       'docker',        'development'),
('Linear',          'https://linear.app',           'linear',        'development'),
('Jira',            'https://jira.atlassian.com',   'jira',          'development'),
('Sentry',          'https://sentry.io',            'sentry',        'development'),
('Grafana',         'https://grafana.com',          'grafana',       'development'),
('Stack Overflow',  'https://stackoverflow.com',    'stackoverflow', 'development'),
('CodePen',         'https://codepen.io',           'codepen',       'development'),
('Portainer',       'https://portainer.io',         'portainer',     'development'),
('Gitea',           'https://gitea.com',            'gitea',         'development'),

-- Email
('Gmail',       'https://mail.google.com',   'gmail',              'email'),
('Outlook',     'https://outlook.live.com',  'microsoft-outlook',  'email'),
('Fastmail',    'https://app.fastmail.com',  'fastmail',           'email'),
('HEY',         'https://app.hey.com',       'hey',               'email'),
('Tutanota',    'https://app.tuta.com',      'tutanota',           'email'),
('Zoho Mail',   'https://mail.zoho.com',     'zoho-mail',          'email'),
('Skiff Mail',  'https://app.skiff.com',     'skiff',              'email'),

-- Finance
('PayPal',    'https://paypal.com',               'paypal',   'finance'),
('Stripe',    'https://dashboard.stripe.com',     'stripe',   'finance'),
('Wise',      'https://wise.com',                 'wise',     'finance'),
('Coinbase',  'https://coinbase.com',             'coinbase', 'finance'),

-- Google
('Google Calendar',  'https://calendar.google.com',  'google-calendar',  'google'),
('Google Drive',     'https://drive.google.com',     'google-drive',     'google'),
('Google Maps',      'https://maps.google.com',      'google-maps',      'google'),
('Google Photos',    'https://photos.google.com',    'google-photos',    'google'),
('Google Contacts',  'https://contacts.google.com',  'google-contacts',  'google'),
('Google Keep',      'https://keep.google.com',      'google-keep',      'google'),
('Google Meet',      'https://meet.google.com',      'google-meet',      'google'),
('Google Docs',      'https://docs.google.com',      'google-docs',      'google'),
('Google Sheets',    'https://sheets.google.com',    'google-sheets',    'google'),

-- Media
('Apple Music',  'https://music.apple.com',   'apple-music',  'media'),
('Spotify',      'https://open.spotify.com',  'spotify',      'media'),
('YouTube',      'https://youtube.com',       'youtube',      'media'),
('YouTube Music','https://music.youtube.com', 'youtube-music','media'),
('Netflix',      'https://netflix.com',       'netflix',      'media'),
('Disney+',      'https://disneyplus.com',    'disney-plus',  'media'),
('Hulu',         'https://hulu.com',          'hulu',         'media'),
('Max',          'https://max.com',           'hbo-max',      'media'),
('Twitch',       'https://twitch.tv',         'twitch',       'media'),
('SoundCloud',   'https://soundcloud.com',    'soundcloud',   'media'),
('Tidal',        'https://listen.tidal.com',  'tidal',        'media'),
('Plex',         'https://app.plex.tv',       'plex',         'media'),
('Jellyfin',     'https://jellyfin.org',      'jellyfin',     'media'),
('Deezer',       'https://deezer.com',        'deezer',       'media'),
('Amazon Music', 'https://music.amazon.com',  'amazon-music', 'media'),
('Crunchyroll',  'https://crunchyroll.com',   'crunchyroll',  'media'),
('Peacock',      'https://peacocktv.com',     'peacock',      'media'),

-- Productivity
('Notion',       'https://notion.so',          'notion',    'productivity'),
('Todoist',      'https://todoist.com',        'todoist',   'productivity'),
('Trello',       'https://trello.com',         'trello',    'productivity'),
('Asana',        'https://app.asana.com',      'asana',     'productivity'),
('Airtable',     'https://airtable.com',       'airtable',  'productivity'),
('ClickUp',      'https://app.clickup.com',    'clickup',   'productivity'),
('Monday.com',   'https://monday.com',         'monday',    'productivity'),
('Coda',         'https://coda.io',            'coda',      'productivity'),
('Basecamp',     'https://basecamp.com',       'basecamp',  'productivity'),
('Obsidian',     'https://obsidian.md',        'obsidian',  'productivity'),

-- Proton
('Proton Mail',     'https://mail.proton.me',       'protonmail',       'proton'),
('Proton Drive',    'https://drive.proton.me',      'proton-drive',     'proton'),
('Proton Calendar', 'https://calendar.proton.me',   'proton-calendar',  'proton'),
('Proton VPN',      'https://account.protonvpn.com','proton-vpn',       'proton'),
('Proton Pass',     'https://pass.proton.me',       'proton-pass',      'proton'),

-- Social
('X',          'https://x.com',                'x',          'social'),
('Reddit',     'https://reddit.com',           'reddit',     'social'),
('Mastodon',   'https://mastodon.social',      'mastodon',   'social'),
('Bluesky',    'https://bsky.app',             'bluesky',    'social'),
('Threads',    'https://threads.net',          'threads',    'social'),
('LinkedIn',   'https://linkedin.com',         'linkedin',   'social'),
('Instagram',  'https://instagram.com',        'instagram',  'social'),
('Facebook',   'https://facebook.com',         'facebook',   'social'),
('Pinterest',  'https://pinterest.com',        'pinterest',  'social'),
('TikTok',     'https://tiktok.com',           'tiktok',     'social'),
('Hacker News','https://news.ycombinator.com', 'hacker-news','social'),

-- Shopping
('Amazon',      'https://amazon.com',      'amazon',     'shopping'),
('eBay',        'https://ebay.com',        'ebay',       'shopping'),
('Etsy',        'https://etsy.com',        'etsy',       'shopping'),
('AliExpress',  'https://aliexpress.com',  'aliexpress', 'shopping'),

-- Utilities
('Wikipedia',    'https://wikipedia.org',          'wikipedia',  'utilities'),
('Bitwarden',   'https://vault.bitwarden.com',     'bitwarden',  'utilities'),
('1Password',   'https://my.1password.com',        '1password',  'utilities'),
('Speedtest',   'https://speedtest.net',           'speedtest',  'utilities'),
('DeepL',       'https://deepl.com/translator',    'deepl',      'utilities'),
('WolframAlpha','https://wolframalpha.com',        'wolfram',    'utilities'),
('Raindrop.io', 'https://app.raindrop.io',        'raindrop',   'utilities'),
('Pocket',      'https://getpocket.com',           'pocket',     'utilities');
SQL
}

waki_catalog_list() {
  waki_db_query "SELECT id, name, url, icon_slug, category
                 FROM waki_webapps ORDER BY category, name;"
}

waki_catalog_get() {
  local name
  name=$(waki_sql_escape "$1")
  waki_db_query "SELECT id, name, url, icon_slug, category
                 FROM waki_webapps WHERE name = '$name' LIMIT 1;"
}
