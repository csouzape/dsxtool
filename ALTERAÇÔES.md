# ALTERAÇÔES

## Data
- 2026-04-04

## Erros encontrados (classificacao)

### Fatais
- Execucao de scripts remotos por pipe para shell em modulos de shell, ghostty e desenvolvimento.
- Atualizacao destrutiva com reset hard no bootstrap.
- Atualizacao destrutiva com reset hard no modulo dsxconfig.

### Medios
- Inconsistencia de modo estrito (`set -uo pipefail`) em varios scripts.
- Parsing fragil de API para URL de download do JetBrains Toolbox e Lutris.
- Uso de key import por pipe no setup de VirtualBox (Debian).

### Basicos
- Risco de falha silenciosa no install de fontes por glob sem validacao de arquivos.
- Bug de splitting no instalador de desktop para listas de pacotes.
- Falta de backup antes de alterar `~/.zshrc`.

## Melhorias implementadas no codigo

### Seguranca
- Removido pipe direto `curl | bash/sh` em:
  - `modules/shell_personalization.sh` (oh-my-zsh, fisher)
  - `modules/ghostty.sh` (installer Debian)
  - `modules/development_setup.sh` (Rustup, NVM, PNPM, Zed, Docker)
- Alterado fluxo para baixar script temporario, executar e limpar arquivo.
- Import de chave do VirtualBox sem pipe direto, com arquivo temporario.

### Robustez
- Padronizado `set -euo pipefail` em:
  - `install.sh`
  - `modules/install_apps.sh`
  - `modules/development_setup.sh`
  - `modules/setup_virtualization.sh`
  - `modules/setup_gaming.sh`
  - `modules/setup_printer.sh`
  - `modules/setup_bluetooth.sh`
  - `modules/dsxconfig.sh`
- Atualizacao no `bootstrap.sh` usando `git pull --ff-only` para evitar sobrescrita destrutiva.
- Atualizacao no `modules/dsxconfig.sh` usando `checkout testing` + `pull --ff-only`.

### Correcao de bugs
- `modules/change_desktop.sh`: corrigido install para multiplos pacotes usando array segura.
- `modules/fonts.sh`: adicionada validacao de TTF e copia segura dos arquivos.
- `modules/shell_personalization.sh`: criado backup de `~/.zshrc` antes de alterar plugins.
- `modules/setup_gaming.sh`: parsing de release do Lutris com `jq` quando disponivel e fallback.
- `modules/development_setup.sh`: parsing de URL JetBrains Toolbox com `jq` quando disponivel e fallback.

## Pendencias recomendadas
- Adicionar verificacao de checksum (SHA256) para downloads de binarios/pacotes.
- Criar CI com `bash -n` e `shellcheck` em todos os scripts.
- Revisar consistencia de idioma (PT/EN) nas mensagens de interface.
- Remover funcoes `main()` nao usadas em modulos onde o entrypoint ja e externo.

## Segunda rodada de auditoria (reanalise completa)

### Novos problemas encontrados

#### Fatal
- `modules/flatpak.sh` nao expunha a funcao `setup_flatpak` esperada pelo dispatcher de `install.sh`, e executava `main "$@"` no `source`. Isso podia causar fluxo incorreto e falha do modulo no menu principal.

#### Medio
- `modules/development_setup.sh` ainda possuia import de chaves via pipe (Kubernetes, HashiCorp, GitHub CLI) sem arquivo intermediario.

#### Basico
- Funcoes `main()` nao utilizadas em `modules/kitty.sh`, `modules/konsole.sh` e `modules/ghostty.sh` (codigo morto/manutencao desnecessaria).

### Correcoes aplicadas nesta segunda rodada
- `modules/flatpak.sh`
  - `main()` substituida por `setup_flatpak()`.
  - Removida autoexecucao `main "$@"` no `source`.
- `modules/development_setup.sh`
  - Kubernetes key: download para arquivo temporario + `gpg --dearmor` sem pipe.
  - HashiCorp key: download para arquivo temporario + `gpg --dearmor` sem pipe.
  - GitHub CLI key: download para arquivo temporario + instalacao segura com `install -Dm644`.
- `modules/kitty.sh`, `modules/konsole.sh`, `modules/ghostty.sh`
  - Removidas funcoes `main()` nao utilizadas.

### Validacao da segunda rodada
- `bash -n` executado em todos os `*.sh`: OK.
- Busca por padroes antigos (`curl|bash/sh`, `set -uo pipefail`, `wget -O -`, `main()`) sem ocorrencias problemáticas remanescentes.

## Terceira rodada de auditoria (reanalise completa)

### Novos problemas encontrados

#### Medio
- Prompts com `read -rp` sem leitura explicita de `/dev/tty` em alguns pontos, com risco de bloqueio/falha em cenarios nao interativos.
- Downloads com nomes fixos em `/tmp` para pacotes (deb/rpm/tar.gz), com risco de colisao e condicao de corrida.

### Correcoes aplicadas nesta terceira rodada
- Padronizacao de prompts para TTY explicito:
  - `core/distros/debian.sh`
  - `core/common.sh`
  - `modules/alacritty.sh`
  - `modules/flatpak.sh`
  - `modules/fonts.sh`
- Troca de artefatos com nome fixo em `/tmp` por arquivos/diretorios temporarios unicos:
  - `modules/install_apps.sh` (Google Chrome .deb/.rpm)
  - `modules/setup_gaming.sh` (Lutris .deb)
  - `modules/development_setup.sh` (Minikube .deb/.rpm e lazygit)

### Validacao da terceira rodada
- `bash -n` executado em todos os `*.sh`: OK.
- Revarredura de padroes sensiveis concluida sem regressao de `set -uo pipefail` ou `curl|bash/sh`.

## Quarta rodada de auditoria (final)

### Novos problemas encontrados

#### Medio
- Alguns downloads ainda podiam falhar silenciosamente por uso de `curl` sem `--fail` em fluxos de instalacao de pacotes.
- Dependencia implicita de `unzip` no instalador de fontes sem validacao previa.
- Dependencia implicita de `wget` para Chrome em ambientes minimos.

### Correcoes aplicadas nesta rodada final
- `modules/development_setup.sh`
  - JetBrains Toolbox e Oracle SQL Developer: `curl -fL` para erro explicito em HTTP falho.
  - lazygit: parsing de versao com `jq` quando disponivel, fallback com `grep`, validacao de versao nao vazia e download com `curl -fLo`.
- `modules/setup_gaming.sh`
  - Download do Lutris com `curl -fsSLo` para nao aceitar resposta HTTP com erro.
- `modules/fonts.sh`
  - Verificacao e instalacao de `unzip` quando ausente.
  - Download de fonte com `curl -fsSLo`.
- `modules/install_apps.sh`
  - Google Chrome (deb/rpm): fallback para `curl -fL` quando `wget` nao estiver disponivel.

### Validacao da rodada final
- `bash -n` executado em todos os scripts: OK.
- Revarredura de padroes de risco (`set -uo pipefail`, `curl -L` sem fail, `curl -sSLo`, `wget -O -`) sem ocorrencias remanescentes relevantes.
