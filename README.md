<!DOCTYPE html>
<html lang="pt-br">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>

<div align="center">
  <h1 style="margin-bottom: 15px;">🔒 Fechadura Eletrônica com FPGA</h1>
  <img 
    src="https://i.redd.it/sn9gvelvf3291.gif" 
    width="800px" 
    height="400px" 
    style="border-radius:10px; display:block; margin:auto; padding:1px; margin-bottom: 15px;" 
    alt="door lock" 
  />
  <p style="margin-top: 0; margin-bottom: 10px;">
    <a href="LICENSE"><img src="https://img.shields.io/badge/Licença-MIT-blue.svg?style=for-the-badge" alt="Licença"></a>
    <img src="https://img.shields.io/badge/Linguagem-SystemVerilog-blueviolet?style=for-the-badge&logo=intel" alt="Linguagem">
    <img src="https://img.shields.io/badge/Tecnologia-FPGA-orange?style=for-the-badge&logo=altera" alt="Tecnologia">
    <img src="https://img.shields.io/badge/Status-Completo-brightgreen?style=for-the-badge" alt="Status">
  </p>
  <p style="margin-top: 0;">Um sistema avançado de controle de acesso implementado em FPGA, com múltiplos recursos de segurança e configuração personalizável através de um teclado matricial.</p>
</div>

<h2>📋 Índice</h2>
<ul>
  <li><a href="#recursos-principais">Recursos Principais</a></li>
  <li><a href="#arquitetura-do-sistema">Arquitetura do Sistema</a></li>
  <li><a href="#estrutura-de-arquivos">Estrutura de Arquivos</a></li>
  <li><a href="#dependencias-e-ferramentas">Dependências e Ferramentas</a></li>
  <li><a href="#instalacao-e-execucao">Instalação e Execução</a></li>
  <li><a href="#como-utilizar">Como Utilizar</a></li>
  <li><a href="#documentacao-tecnica">Documentação Técnica</a></li>
  <li><a href="#como-contribuir">Como Contribuir</a></li>
  <li><a href="#autores">Autores</a></li>
  <li><a href="#licenca">Licença</a></li>
</ul>

<h2 id="recursos-principais">✨ Recursos Principais</h2>
<div>
  <p>
    🔑 &nbsp; <b>Acesso Multi-PIN:</b> Suporte para até 4 PINs de usuário, além de um PIN mestre.<br>
    ⚙️ &nbsp; <b>Modo de Configuração:</b> PIN mestre permite personalizar todas as funções do sistema.<br>
    ⏱ &nbsp; <b>Temporizadores:</b> Travamento automático e alerta de porta aberta configuráveis.<br>
    🚨 &nbsp; <b>Sistema Anti-intrusão:</b> Bloqueio progressivo do teclado após tentativas de acesso inválidas.<br>
    🔄 &nbsp; <b>Reset de Fábrica:</b> Restauração segura das configurações originais de fábrica.
  </p>
</div>

<h2 id="arquitetura-do-sistema">🧩 Arquitetura do Sistema</h2>
<p>O projeto é modular, centrado em uma máquina de estados principal que gerencia os modos de operação e configuração.</p>

<h3 id="componentes-principais">📌 Componentes Principais</h3>
<ul>
  <li><strong>Entradas</strong>:
    <ul>
      <li>Teclado matricial 4x4 para entrada de senhas e comandos.</li>
      <li>Sensor de porta para detectar se a porta está aberta ou fechada.</li>
      <li>Botão de reset para restauração do sistema.</li>
    </ul>
  </li>
  <li><strong>Saídas</strong>:
    <ul>
      <li>Display de 7 segmentos com 6 dígitos para feedback visual.</li>
      <li>LEDs de status (travado, destravado, erro).</li>
      <li>Buzzer para alertas sonoros.</li>
    </ul>
  </li>
</ul>

<h3 id="modulos-logicos">🖥️ Módulos Lógicos (SystemVerilog)</h3>
<div align="center">
<pre><code class="language-mermaid">
graph TD
    A[Fechadura Top] --> B[Módulo Operacional]
    A --> C[Módulo de Setup]

    subgraph "Módulos de Lógica"
        B --> D[Verificar Senha]
        C --> E[Atualizar PIN Mestre]
        C --> F[Montar Novo PIN]
    end

    subgraph "Drivers/Utils"
        G[Decodificador de Teclado]
        H[Controlador do Display 7-Seg]
        I[Divisor de Frequência]
    end

    A --> G
    A --> H
    A --> I
</code></pre>
</div>

<h2 id="estrutura-de-arquivos">📂 Estrutura de Arquivos</h2>
<p>A estrutura do projeto está organizada da seguinte forma:</p>
<pre><code>
/
├── docs/                   # Documentação, diagramas e vídeos
├── modules/                # Módulos SystemVerilog reutilizáveis
│   ├── main/               # Módulos principais da máquina de estados
│   └── utils/              # Módulos de suporte e drivers
├── project/                # Projetos do Quartus para cada módulo e para o sistema completo
└── README.md               # Este arquivo
</code></pre>

<h2 id="dependencias-e-ferramentas">🛠️ Dependências e Ferramentas</h2>
<div align="center">
  <img src="https://img.shields.io/badge/Placa_Alvo-DE1--SoC | Cyclone V-informational?style=for-the-badge" alt="Placa Alvo">
  <img src="https://img.shields.io/badge/Software-Quartus Prime 18.1%2B-purple?style=for-the-badge" alt="Software">
</div>

<h2 id="instalacao-e-execucao">🚀 Instalação e Execução</h2>
<ol>
  <li><strong>Clone o repositório</strong>:
    <pre><code class="language-bash">git clone https://github.com/marcovins/fpga-doorlock-system.git</code></pre>
  </li>
  <li><strong>Abra o projeto no Quartus</strong>:
    <ul>
      <li>Navegue até a pasta <code>project/fechaduratop/</code>.</li>
      <li>Abra o arquivo de projeto <code>fechaduratop.qpf</code>.</li>
    </ul>
  </li>
  <li><strong>Compile o projeto</strong>:
    <ul>
      <li>Inicie a compilação (Processing > Start Compilation).</li>
    </ul>
  </li>
  <li><strong>Grave na FPGA</strong>:
    <ul>
      <li>Conecte a placa DE1-SoC ao computador.</li>
      <li>Use o programador (Tools > Programmer) para carregar o arquivo <code>.sof</code> gerado em <code>project/fechaduratop/output_files/</code>.</li>
    </ul>
  </li>
</ol>

<h2 id="como-utilizar">💡 Como Utilizar</h2>
<details>
  <summary><strong>🔓 Modo de Operação Normal</strong></summary>
  <ol>
    <li><strong>Inserir PIN</strong>: Digite um código de 4 dígitos.</li>
    <li><strong>Confirmar</strong>: Pressione <code>*</code> para validar.</li>
    <li><strong>Acesso Concedido</strong>: O LED verde acende e a porta é destravada pelo tempo configurado.</li>
    <li><strong>Acesso Negado</strong>: O LED vermelho pisca e o buzzer soa.</li>
  </ol>
</details>

<details>
  <summary><strong>🛡️ Proteção Automática</strong></summary>
  <ul>
    <li>Após 3 tentativas de senha incorretas, o sistema é bloqueado temporariamente.</li>
    <li>O tempo de bloqueio aumenta a cada nova falha (10s, 20s, 30s).</li>
  </ul>
</details>

<details>
  <summary><strong>⚙️ Modo de Configuração (Acesso com PIN Mestre)</strong></summary>
  <ol>
    <li>Entre no modo de configuração inserindo o PIN Mestre e pressionando <code>*</code>.</li>
    <li>Use o teclado para navegar pelas opções do menu:
      <ul>
        <li><strong>1</strong>: Ligar/Desligar o buzzer.</li>
        <li><strong>2</strong>: Configurar tempo do alerta de porta aberta (5-60s).</li>
        <li><strong>3</strong>: Ajustar tempo de autotravamento (5-60s).</li>
        <li><strong>4</strong>: Gerenciar PINs de usuário (adicionar, remover, alterar).</li>
      </ul>
    </li>
    <li>Pressione <code>#</code> para cancelar ou voltar ao menu anterior.</li>
  </ol>
</details>

<details>
  <summary><strong>🔄 Reset de Fábrica</strong></summary>
  <ul>
    <li>Mantenha o botão de reset pressionado por 5 segundos.</li>
    <li>Os displays piscarão e um som será emitido, indicando que as configurações padrão foram restauradas.</li>
  </ul>
</details>

<h2 id="demonstracao">🎥 Demonstração</h2>
<div align="center">
  <p>Assista ao vídeo de demonstração do sistema em funcionamento:</p>
  <a href="./docs/fechadura.mp4">Demonstração da Fechadura Eletrônica</a>
</div>

<h2 id="documentacao-tecnica">📑 Documentação Técnica</h2>
<div align="center">
  <table>
    <tr>
      <th>Arquivo</th>
      <th>Descrição</th>
    </tr>
    <tr>
      <td><a href="./docs/Projeto - PSD - Fechadura Eletrônica.pdf">📄 Projeto - PSD - Fechadura Eletrônica.pdf</a></td>
      <td>Especificação funcional completa do sistema.</td>
    </tr>
    <tr>
      <td><a href="./docs/diagrama operacional.pdf">📄 diagrama operacional.pdf</a></td>
      <td>Fluxograma do modo de operação normal.</td>
    </tr>
    <tr>
      <td><a href="./docs/diagrama setup.pdf">📄 diagrama setup.pdf</a></td>
      <td>Fluxograma do modo de configuração.</td>
    </tr>
  </table>
</div>

<h2 id="como-contribuir">🤝 Como Contribuir</h2>
<div align="center">
  <p>Contribuições são bem-vindas! Se você tem ideias para melhorias ou encontrou algum problema, sinta-se à vontade para abrir uma <strong>Issue</strong> ou enviar um <strong>Pull Request</strong>.</p>
</div>

<h2 id="autores">👨‍💻 Autores</h2>
<table align="center">
  <tr>
    <td align="center">
      <a href="https://github.com/marcovins">
        <img src="https://github.com/marcovins.png" width="100px" style="border-radius:50%;" alt="Foto de Marcos Belo"/><br />
        <sub><b>Marcos Belo</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/JeffersonAmorimdaCosta">
        <img src="https://github.com/JeffersonAmorimdaCosta.png" width="100px" style="border-radius:50%;" alt="Foto de Jefferson Amorim"/><br />
        <sub><b>Jefferson Amorim</b></sub>
      </a>
    </td>
  </tr>
  <tr>
    <td align="center">
      <a href="https://github.com/marcovins">
        <img src="https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white" />
      </a>
      <a href="https://www.linkedin.com/in/marcovins/">
        <img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" />
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/JeffersonAmorimdaCosta">
        <img src="https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white" />
      </a>
      <a href="https://www.linkedin.com/in/jeffersonamorimdacosta/">
        <img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" />
      </a>
    </td>
  </tr>
</table>

<h2 id="licenca">📝 Licença</h2>
<div align="center">
  <p>Este projeto está distribuído sob a licença MIT. Veja o arquivo <a href="LICENSE">LICENSE</a> para mais detalhes.</p>
</div>

</body>
</html>