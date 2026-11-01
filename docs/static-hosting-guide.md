# Example: How to deploy static assets from another repo (e.g., bloggo, mowik)
#
# 1. Add these secrets to the OTHER repo (Settings → Secrets → Actions):
#    - VPS_HOST
#    - VPS_SSH_PORT
#    - VPS_HOST_KEY_FINGERPRINT
#    - ANSIBLE_SSH_KEY
#    (Same values as in vps-iac repo)
#
# 2. Create .github/workflows/deploy-static.yml in the OTHER repo:
#
# name: Deploy Static Assets
#
# on:
#   push:
#     branches: [main]
#     paths:
#       - "dist/**"        # or your build output directory
#       - ".github/workflows/deploy-static.yml"
#   workflow_dispatch:
#
# jobs:
#   build:
#     name: Build
#     runs-on: ubuntu-latest
#     steps:
#       - uses: actions/checkout@v6.5.0
#       - uses: actions/setup-node@v4
#         with:
#           node-version: '20'
#           cache: 'npm'
#       - run: npm ci
#       - run: npm run build
#       - uses: actions/upload-artifact@v4
#         with:
#           name: static-assets
#           path: dist/
#           retention-days: 1
#
#   deploy:
#     name: Deploy to VPS
#     needs: build
#     uses: a-float/vps-iac/.github/workflows/deploy-static.yml@main
#     secrets: inherit
#     with:
#       source-dir: dist
#       target-subdir: bloggo      # change per project
#       delete-extra: true
#
# 3. Done! On push to main, your static assets will be at:
#    https://static.mati.local/bloggo/
#
# For a custom domain (e.g., assets.yourdomain.com):
# - Add DNS A record pointing to VPS IP
# - Add to Caddyfile.j2:
#   
#   http://assets.yourdomain.com {
#       root /srv/static
#       file_server {
#           browse
#           precompressed gzip zstd
#       }
#       header {
#           Cache-Control "public, max-age=31536000, immutable"
#           -Server
#       }
#   }