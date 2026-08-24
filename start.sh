#!/bin/bash

# 作業ディレクトリをスクリプトのある場所に移動
cd "$(dirname "$0")"

# Dockerデーモンが起動しているか確認
if ! docker info > /dev/null 2>&1; then
    echo "エラー: Docker デスクトップが起動していないようです。"
    echo "Docker Desktop を起動してからもう一度お試しください。"
    exit 1
fi

# APIキーの確認
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "エラー: ANTHROPIC_API_KEY が設定されていません。"
    echo ".env ファイルを作成して ANTHROPIC_API_KEY=sk-ant-... と記入してください。"
    exit 1
fi

# イメージが存在するか確認（なければ構築）
if [[ "$(docker images -q claude-code-env 2> /dev/null)" == "" ]]; then
    echo "--- 初回起動のため Docker イメージを構築しています... ---"
    docker build -t claude-code-env .
fi

# Claude 設定の永続化ディレクトリを用意（テーマ・信頼フォルダ等の選択結果を保存）
mkdir -p "$(pwd)/.claude-home"

# /root/.claude.json（信頼フォルダ承認・オンボーディング状態）の永続化ファイルを用意
# 起動時にコンテナの /root/.claude.json へバインドマウントする
[ ! -f "$(pwd)/.claude-home/dot-claude.json" ] && echo '{}' > "$(pwd)/.claude-home/dot-claude.json"

# ===== 追加マウント（参照フォルダ）の対話入力 =====
EXTRA_MOUNT_ARGS=()
echo ""
echo "参照フォルダのパスを入力してください"
echo "(空Enterで指定なし。/work と /youtube_output は常時マウント済み)"
read -r -p "> " EXTRA_PATH

if [ -n "$EXTRA_PATH" ]; then
    # チルダ展開（~ を $HOME に置換）
    EXTRA_PATH="${EXTRA_PATH/#\~/$HOME}"

    # 末尾スラッシュ除去
    EXTRA_PATH="${EXTRA_PATH%/}"

    # 存在チェック
    if [ ! -d "$EXTRA_PATH" ]; then
        echo "エラー: 指定されたフォルダが見つかりません: $EXTRA_PATH"
        echo "パスを確認してやり直してください。"
        exit 1
    fi

    EXTRA_MOUNT_ARGS=(-v "${EXTRA_PATH}:/external")
    echo "→ ${EXTRA_PATH} を /external にマウントしました（読み書き可）"
else
    echo "→ 追加マウントなしで起動します"
fi
echo ""

echo "--- Claude Code コンテナを起動します ---"
# コンテナ内で直接 claude を実行するか、引数があればそれを渡す
# 引数がない場合は対話モードで起動
if [ $# -eq 0 ]; then
    docker run -it --rm \
        --name claude-pc \
        -v "$(pwd):/work" \
        -v "$(pwd)/.claude-home:/root/.claude" \
        -v "$(pwd)/.claude-home/dot-claude.json:/root/.claude.json" \
        -v "/Users/hahiro/Desktop/youtube_output:/youtube_output" \
        -v "/Users/hahiro/Desktop/hohner-share:/hohner-share:ro" \
        -v "/Users/hahiro/Desktop/hohner-share/memory/hohner-share:/work/memory" \
        -v "/Users/hahiro/Desktop/hohner-share/memory/hohner-share:/root/.claude/projects/-work/memory" \
        "${EXTRA_MOUNT_ARGS[@]}" \
        -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
        claude-code-env \
        claude
else
    docker run -it --rm \
        --name claude-pc \
        -v "$(pwd):/work" \
        -v "$(pwd)/.claude-home:/root/.claude" \
        -v "$(pwd)/.claude-home/dot-claude.json:/root/.claude.json" \
        -v "/Users/hahiro/Desktop/youtube_output:/youtube_output" \
        -v "/Users/hahiro/Desktop/hohner-share:/hohner-share:ro" \
        -v "/Users/hahiro/Desktop/hohner-share/memory/hohner-share:/work/memory" \
        -v "/Users/hahiro/Desktop/hohner-share/memory/hohner-share:/root/.claude/projects/-work/memory" \
        "${EXTRA_MOUNT_ARGS[@]}" \
        -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
        claude-code-env \
        claude "$@"
fi
