### Install terraform / git / unzip / helm
sudo apt-get update
sudo apt-get install -y git-all
sudo apt-get install -y unzip
sudo apt-get install -y wget
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
#### Opentofu install
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://get.opentofu.org/opentofu.gpg | sudo tee /etc/apt/keyrings/opentofu.gpg >/dev/null
curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | sudo gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg >/dev/null
sudo chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg
echo \
  "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main
deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" | \
  sudo tee /etc/apt/sources.list.d/opentofu.list > /dev/null
sudo chmod a+r /etc/apt/sources.list.d/opentofu.list
sudo apt-get update
sudo apt-get install -y tofu=1.11.5
#### Helm installation
sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm
### Atlantis user and binary
sudo useradd -m atlantis
sudo cat << EOF >> /home/atlantis/repos.yaml
repos:
- id: /.*/
  plan_requirements: [mergeable]
  apply_requirements: [mergeable, approved]
  import_requirements: [mergeable]
  # All repos can set their own plan and import
  # apply will still follow this server rule
  allowed_overrides: [import_requirements,workflow]
EOF
sudo mkdir /home/atlantis/data
sudo chown -R atlantis:atlantis /home/atlantis/data
sudo chown atlantis:atlantis /home/atlantis/repos.yaml
sudo wget https://github.com/runatlantis/atlantis/releases/download/v0.40.0/atlantis_linux_amd64.zip
sudo unzip atlantis_linux_amd64.zip && rm atlantis_linux_amd64.zip
sudo mv atlantis /home/atlantis/
sudo chown atlantis:atlantis /home/atlantis/atlantis
### Bringin GH tokens to run atlantis
GITHUB_TOKEN=$(gcloud secrets versions access latest --secret="${gh_token_secret_name}" --project="${PROJECT_ID}")
WEBHOOK_SECRET=$(gcloud secrets versions access latest --secret="${webhook_token_secret_name}" --project="${PROJECT_ID}")

### Creating the systemd service and starting
sudo tee /etc/systemd/system/atlantis.service <<EOF
[Unit]
Description=Atlantis OpenTofu Automation
After=network.target

[Service]
Type=simple
User=atlantis
Group=atlantis
WorkingDirectory=/home/atlantis
Environment="ATLANTIS_DATA_DIR=/home/atlantis/data"
Environment="ATLANTIS_GH_TOKEN=$GITHUB_TOKEN"
Environment="ATLANTIS_GH_WEBHOOK_SECRET=$WEBHOOK_SECRET"
Environment="ATLANTIS_GH_USER=fernhtls"
Environment="ATLANTIS_REPO_ALLOWLIST=${repos_allowlist}"
Environment="ATLANTIS_DEFAULT_TF_DISTRIBUTION=opentofu"
Environment="ATLANTIS_AUTOMERGE=true"
Environment="ATLANTIS_REPO_CONFIG=/home/atlantis/repos.yaml"
ExecStart=/home/atlantis/atlantis server
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable atlantis
sudo systemctl start atlantis
