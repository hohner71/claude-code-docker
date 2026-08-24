# Node.js 20 (Debian Bookworm) をベースに使用
FROM node:20-bookworm

# パッケージリストを更新し、必要なツールをインストール
# (git, curl, procpsなどはClaude Codeの動作やデバッグに役立ちます)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    procps \
    vim \
    chromium \
    fonts-noto-cjk \
    fonts-ipafont \
    python3-pip \
    && pip3 install feedparser rich --break-system-packages \
    && rm -rf /var/lib/apt/lists/*

# Claude Code をグローバルにインストール
RUN npm install -g @anthropic-ai/claude-code

# 作業ディレクトリを /work に設定
# (起動時にここがMacのデスクトップと同期されます)
WORKDIR /work

# コンテナ起動時に bash を実行
CMD ["/bin/bash"]
