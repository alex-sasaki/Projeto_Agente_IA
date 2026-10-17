# Caça ao Tesouro com Agente Inteligente em Prolog

Agente baseado no ciclo de **Percepção-Ação** desenvolvido em Prolog. O agente navega por um grid bidimensional de dimensões configuráveis, seguindo uma cadeia encadeada de pistas qualitativas até encontrar e coletar o tesouro, sem o uso de heurísticas numéricas ou algoritmos de aprendizado.

---

## Sumário
- [Sobre o Projeto](#-sobre-o-projeto)
- [Pré-requisitos e Instalação](#-pré-requisitos-e-instalação)
  - [1. Instalação do SWI-Prolog](#1-instalação-do-swi-prolog)
  - [2. Configuração no VS Code](#2-configuração-no-vs-code)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Como Executar](#-como-executar)
- [Detalhes da Implementação](#-detalhes-da-implementação)

---

## Sobre o Projeto

O ambiente do problema consiste em um grid $N \times M$ onde:
- Um conjunto de $K$ pistas e $1$ tesouro são distribuídos em posições exclusivas.
- Cada pista contém uma **orientação relacional/qualitativa** (`norte`, `sul`, `leste`, `oeste`) apontando a direção da próxima pista.
- O agente inicia com uma dica inicial e percorre o mapa de forma segura e estrita, utilizando uma busca em largura (BFS) em grafos sobre o histórico de passos para contornar áreas já exploradas e evitar ciclos ou travamentos.
- Toda a gerência de estado (posição atual, dica corrente e células visitadas) é controlada via **recursão pura**, dispensando efeitos colaterais na base de dados global.

---

## Pré-requisitos e Instalação

### 1. Instalação do SWI-Prolog

O projeto requer o interpretador oficial **SWI-Prolog**.

* **Ubuntu / Debian:**
  ```bash
  sudo apt update
  sudo apt install swi-prolog
  ```

* **Fedora:**
  ```bash
  sudo dnf install pl
  ```

* **macOS (via Homebrew):**
  ```bash
  brew install swi-prolog
  ```

* **Windows:**
  1. Baixe o instalador no site oficial: [SWI-Prolog Downloads](https://www.swi-prolog.org/download/stable).
  2. Execute o instalador e **certifique-se de marcar a opção**: `Add swipl to the system PATH`.

Para validar a instalação, abra um terminal e verifique:
```bash
swipl --version
```

---

### 2. Configuração no VS Code

1. Abra o VS Code.
2. Abra a aba de Extensões (`Ctrl + Shift + X` ou `Cmd + Shift + X`).
3. Pesquise e instale uma das extensões recomendadas para suporte a Prolog:
   - **VSC-Prolog** (desenvolvido por *Arthur Wang*).
   - **Prolog** (desenvolvido por *Guenther Schmidt*).
4. *(Opcional)* Se o executável não for detectado automaticamente, configure o caminho nas configurações do VS Code (`settings.json`):
   * **Linux/macOS:**
     ```json
     "prolog.executablePath": "/usr/bin/swipl"
     ```
   * **Windows:**
     ```json
     "prolog.executablePath": "C:\\Program Files\\swipl\\bin\\swipl.exe"
     ```

---

## Estrutura do Projeto

```text
caca-ao-tesouro/
├── CacaTesouro.pl      # Código-fonte principal do agente e regras do grid
└── README.md       # Instruções e documentação do projeto
```

---

## Como Executar

### 1. Abrir o terminal no diretório do projeto
No VS Code, abra o terminal integrado (`Ctrl + \``) e navegue até a pasta onde está o arquivo `CacaTesouro.pl`.

### 2. Iniciar o console do SWI-Prolog
Carregue o arquivo diretamente no interpretador:
```bash
swipl CacaTesouro.pl
```

O terminal exibirá o prompt interativo:
```prolog
?- 
```

### 3. Executar o Agente
O predicado principal segue a assinatura:
```prolog
iniciar_caca(+Largura, +Altura, +NumPistas, +PosicaoInicial).
```

* **Parâmetros:**
  - `Largura` (inteiro): Limite do eixo X ($MaxX$).
  - `Altura` (inteiro): Limite do eixo Y ($MaxY$).
  - `NumPistas` (inteiro): Quantidade de pistas intermediárias a serem sorteadas.
  - `PosicaoInicial` (`pos(X, Y)`): Célula de partida do agente.

#### Exemplos de Consulta:

* **Grid 5x5 com 3 pistas partindo de (1, 1):**
  ```prolog
  ?- iniciar_caca(5, 5, 3, pos(1, 1)).
  ```

* **Grid 8x8 com 5 pistas partindo do centro (4, 4):**
  ```prolog
  ?- iniciar_caca(8, 8, 5, pos(4, 4)).
  ```

* **Grid 10x10 com 8 pistas partindo de (10, 10):**
  ```prolog
  ?- iniciar_caca(10, 10, 8, pos(10, 10)).
  ```

### 4. Recarregar após alterações no código
Caso modifique o arquivo `CacaTesouro.pl`, não é necessário reiniciar o terminal. No prompt do Prolog, use:
```prolog
?- make.
```

Para encerrar o interpretador e voltar ao terminal:
```prolog
?- halt.
```

---

## Detalhes da Implementação

1. **Geração Randômica Válida:** O sorteio das posições utiliza `random_permutation/2` para garantir que a posição inicial, cada uma das pistas e o tesouro nunca ocupem a mesma coordenada física.
2. **Coerência das Dicas:** A orientação associada a cada pista é calculada formalmente em relação à posição da meta seguinte pelo predicado `calcular_dica/3`, garantindo que toda pista forneça uma direção real e factível.
3. **Prevenção de Ciclos e Contorno:** O agente carrega a lista acumuladora de células visitadas como parâmetro recursivo. Se o vizinho na direção da dica já tiver sido visitado, a BFS encontra o menor caminho para contornar o rastro sem entrar em ciclos infinitos.