#!/bin/bash
# 自動化部署腳本 - 部署 Flutter Web 到 GitHub Pages
# 使用方式: ./deploy.sh

set -e

echo "=========================================="
echo "  財務計算工具 - 自動化部署腳本"
echo "=========================================="
echo ""

# 檢查是否在 main branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    echo "❌ 錯誤: 必須在 main branch 執行此腳本"
    echo "   當前 branch: $current_branch"
    exit 1
fi

# 檢查是否有未提交的變更
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  警告: 有未提交的變更"
    echo "   請先提交變更後再執行部署"
    exit 1
fi

echo "✅ 當前 branch: main"
echo ""

# 構建 Flutter Web
echo "📦 開始構建 Flutter Web..."
flutter build web --base-href "/loan_calculator_web/" --release

if [ $? -ne 0 ]; then
    echo "❌ Flutter 構建失敗"
    exit 1
fi

echo "✅ Flutter 構建完成"
echo ""

# 備份 build/web 到臨時目錄
echo "💾 備份構建產物..."
rm -rf /tmp/gh-pages-temp 2>/dev/null || true
cp -r build/web /tmp/gh-pages-temp

echo "✅ 備份完成"
echo ""

# 切換到 gh-pages branch
echo "🔄 切換到 gh-pages branch..."
git checkout gh-pages

if [ $? -ne 0 ]; then
    echo "❌ 切換 branch 失敗"
    rm -rf /tmp/gh-pages-temp
    git checkout main
    exit 1
fi

echo "✅ 已切換到 gh-pages"
echo ""

# 清理舊內容
echo "🧹 清理舊的部署內容..."
git rm -rf . 2>/dev/null || true
git clean -fxd

echo "✅ 清理完成"
echo ""

# 複製新內容
echo "📋 複製新的構建產物..."
cp -r /tmp/gh-pages-temp/* .

# 刪除不需要的檔案
echo "🗑️  刪除不需要的檔案..."
rm -rf android ios macos build .dart_tool .last_build_id .claude 2>/dev/null || true

echo "✅ 檔案處理完成"
echo ""

# 顯示變更摘要
echo "📊 變更摘要:"
git status --short

echo ""

# 提交變更
echo "📝 提交變更到 gh-pages..."
git add -A

if git diff --cached --quiet; then
    echo "ℹ️  沒有需要提交的變更"
    git checkout main
    rm -rf /tmp/gh-pages-temp
    echo ""
    echo "🎉 部署完成（無需更新）"
    exit 0
fi

commit_message="deploy: update web app $(date '+%Y-%m-%d %H:%M:%S')

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

git commit -m "$commit_message"

echo "✅ 提交完成"
echo ""

# 推送到 remote
echo "⬆️  推送到 GitHub..."

# 先嘗試 pull rebase 以防遠端有新變更
echo "   檢查遠端更新..."
git pull origin gh-pages --rebase 2>/dev/null || true

# 推送
git push origin gh-pages

if [ $? -ne 0 ]; then
    echo "❌ 推送失敗"
    git checkout main
    rm -rf /tmp/gh-pages-temp
    exit 1
fi

echo "✅ 推送成功"
echo ""

# 切回 main branch
echo "🔙 切換回 main branch..."
git checkout main

echo "✅ 已切換回 main"
echo ""

# 清理臨時檔案
echo "🧹 清理臨時檔案..."
rm -rf /tmp/gh-pages-temp

echo "✅ 清理完成"
echo ""

echo "=========================================="
echo "  🎉 部署成功！"
echo "=========================================="
echo ""
echo "🌐 網站網址:"
echo "   https://lchuang8211.github.io/loan_calculator_web/"
echo ""
echo "⏰ 通常需要 1-2 分鐘後才能看到更新"
echo "   如果沒有更新，請嘗試強制刷新 (Ctrl+Shift+R)"
echo ""
