// Para trocar a aparência dos elementos, altere apenas este objeto
const ICONES = { agente: '🤖', pista: '📜', obstaculo: '🪨', tesouro: '💰' };

const $ = s => document.querySelector(s);
const posicoes = t => t.match(/pos\(\d+,\s*\d+\)/g).map(p => p.match(/\d+/g).map(Number));
const chave = ([x, y]) => `${x},${y}`;

let estado, timer;

$('#iniciar').onclick = async () => {
  const q = new URLSearchParams({
    x: $('#x').value, y: $('#y').value,
    pistas: $('#pistas').value, obstaculos: $('#obstaculos').value
  });
  const texto = await (await fetch('/api/caca?' + q)).text();
  executar(texto.split('\n').filter(l => l.trim()));
};

function executar(linhas) {
  clearTimeout(timer);
  $('#log').innerHTML = '';

  const cabecalho = linhas.find(l => /^Grid \d+x\d+/.test(l));
  if (!cabecalho) return log(linhas.join(' '));   // ex.: erro de capacidade

  const [largura, altura] = cabecalho.match(/\d+/g).map(Number);
  const itens = {};
  linhas.filter(l => l.startsWith('[CONFIG]')).forEach(l => {
    itens[chave(posicoes(l)[0])] =
      l.includes('Pista') ? 'pista' : l.includes('Obstaculo') ? 'obstaculo' : 'tesouro';
  });

  estado = {
    largura, altura, itens,
    visitadas: new Set(),
    agente: posicoes(linhas.find(l => l.startsWith('Agente em')))[0]
  };
  desenhar();

  const eventos = linhas.filter(l => /^(Avanco|Backtrack|\[PERCEPCAO\]|Sucesso|Fim)/.test(l));
  passo(eventos, 0);
}

function passo(eventos, i) {
  if (i >= eventos.length) return;
  const l = eventos[i];
  if (/^(Avanco|Backtrack)/.test(l)) {
    estado.visitadas.add(chave(estado.agente));
    estado.agente = posicoes(l)[1];
  }
  log(l);
  desenhar();
  timer = setTimeout(() => passo(eventos, i + 1), $('#vel').value);
}

function desenhar() {
  const { largura, altura, itens, visitadas, agente } = estado;
  const grid = $('#grid');
  grid.style.gridTemplateColumns = `repeat(${largura}, auto)`;
  grid.innerHTML = '';
  for (let y = altura; y >= 1; y--) {          // y maior fica no topo
    for (let x = 1; x <= largura; x++) {
      const k = chave([x, y]);
      const tipo = chave(agente) === k ? 'agente' : itens[k];
      const c = document.createElement('div');
      c.className = 'celula ' + (tipo || '') + (visitadas.has(k) ? ' visitada' : '');
      c.textContent = tipo ? ICONES[tipo] : '';
      grid.appendChild(c);
    }
  }
}

function log(texto) {
  const d = document.createElement('div');
  d.textContent = texto;
  if (texto.startsWith('[PERCEPCAO]')) d.className = 'percepcao';
  $('#log').prepend(d);
}
