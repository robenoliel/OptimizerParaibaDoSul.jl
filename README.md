# OptimizerParaibaDoSul.jl

## Introdução

Este projeto em vista um estudo de regras alternativas às da ANA para operação do Sistema Hidráulico Paraíba do Sul. Ele foi desenvolvido como uma extensão do estudo simulatorParaibaDoSul.jl, disponível [aqui](https://github.com/robenoliel/simulatorParaibaDoSul.jl). Por isso, recomenda-se fortemente que o leitor veja sua documentação e se familiarize com seus arquivos antes de examinar o OptimizerParaibaDoSul, que conterá apenas um complemento do que já está apresentado lá.

## Dados de Entrada

A maior parte do simulador deste repositório, para regras alternativas, se assemelha a versão original para regras básicas da ANA. Por isso, a maioria dos arquivos que o simulador utiliza de entrada e saída de dados são os mesmos. Nesse documento será tratado apenas dos materiais que são diferentes desta versão para a anterior, para mais informações acerca dos arquivos que permanecem os mesmos, vide documentação do simulador original, [aqui](https://github.com/robenoliel/simulatorParaibaDoSul.jl). Os dados de entrada separam se em duas pastas, são estas:
* `base_results`: uma pasta que contém dados de entrada e resultados de uma simulação realizada pelas regras operativas da ANA, frutos de uma simulação feita pela versão original do simulador. Esta pasta contém todos os dados de entrada da simulação não-referentes a regras alternativas, tal como vazão histórica, volume dos reservatórios, entre outros. Chama-se a atenção para o fato de que o simulador de regras alternativas **depende dos arquivos desse diretório**, mesmo que as regras operativas da ANA não sejam de interesse para o usuário. Não é recomendado que o usuário edite diretamente estes arquivos, dado que ele contém tanto entradas quanto resultados. Caso deseje-se modificar algum de seus arquivos, recomenda-se que isso seja feito executando um caso chamado `base_results` com o simulador original de regras ANA e os novos parâmetros desejados, e em seguida substitua a pasta `base_results` neste projeto pela nova.
* `function_trials`: pasta que contém diversos casos de regras alternativas que são gerados ou sobreescritos automaticamente ao se executar o simulador, além das configurações de parâmetros relacionados às regras alternativas.

Uma vez que a experimentação com regras alternativas é extremamente empírica, em geral é de maior interesse que sejam executadas diversas simulações, com várias combinações de parâmetros, do que somente um caso único. Por isso, a configuração de parâmetros de regras alternativas (A, B e C) não é feita atribuindo um valor único a cada um desses, mas sim um valor inicial, um final, e um passo de discretização. Isso é feito editando o arquivo `trial_params.csv`, onde para cada parâmetro, A, B e C, pode-se definir:
* `start`: valor inicial.
* `step`: passo da discretização.
* `end`: valor final desejado (pode não ser exatamente o último valor dependendo da multiplicidade de `step`).

## Metodologia

### Visão Geral
As regras estabelecidas pela ANA para operação da usina de Santa Cecília são bastante gerais e não oferecem um regime transitório suave na mudança de um estado operativo para outro. Com o intuito de estabelecer um modelo mais atento a fatores sazonais e mais sensível a pequenas variações de reservatório, foi desenvolvido um conjunto de regras operativas para Santa Cecília alternativas a da ANA, baseada numa curva que relaciona sua defluência ao valor percentual do reservatório equivalente do Sistema Hidráulico Paraíba do Sul.

![rep_page](/figures/modelo.png)

A curva em questão, representada na Figura 4, é dividida em três funções:
* A primeira, em azul, estabelece a defluência mínima. Essa função irá reger a curva até o ponto que intercepta a função em vermelho;
* A segunda, em vermelho é uma parábola de concavidade para baixo. Esta irá reger a defluência até alcançar o valor de 250 m3/s;
* A terceira, em verde, estabelece um limite máximo de defluência de 250 m3/s. Valores superiores a esse serão possíveis apenas para controle de cheia.

O estudo da regra alternativa foi majoritariamente empírico, ou seja, com base principalmente em experimentação. Assim, foram experimentados diversos casos particulares de curvas semelhantes ao caso geral mostrado. Tal diversidade foi criada manipulando três parâmetros, A, B e C, cujos valores afetam, diretamente ou indiretamente, as posições dos três pontos chaves, indicados com círculos no gráfico. Os efeitos de cada um desses parâmetros são:
* A: Determina a posição vertical da curva azul. Para baixos valores, o simulador será relativamente conservador para períodos de reservatório baixo, permitindo operação com baixas vazões, podendo ser inclusive inferiores ao limite mínimo de 160 m3/s. 
* B: Determina a posição horizontal do ponto na qual a parábola irá atingir o valor máximo 250 m3/s. Ou seja, o ponto na qual esta encontra a curva verde. O valor de B varia de forma que o ponto se encontre sempre entre a média mensal e 100%. Para valores altos, o ponto irá se encontrar mais a esquerda desse intervalo, de forma que o sistema será mais arrojado para valores de reservatório equivalente acima da média mensal, liberando mais volume. Reciprocamente, para valores baixos, este estará mais a direita, representando postura mais conservadora.
* C: Determina a posição horizontal do ponto na qual a curva azul de mínimo encontra a parábola. Para valores altos, o ponto será mais a esquerda, colaborando para valores mais arrojados de vazão para volumes de reservatório logo abaixo da média mensal. Reciprocamente, valores baixos manifestam-se como uma postura mais conservadora nessas circunstâncias.

É importante ter em mente que **nem toda combinação de parâmetros resulta em uma curva desejável**. Por exemplo, um dado trio de valores A, B e C pode resultar em uma parábola de concavidade para cima, o que não é de interesse para o modelo. Nesse caso particular, o programa irá identificar que a função é inapropriada e irá eliminar o caso automaticamente. Caso isso ocorra, será alertado na execução. Porém, ainda é importante estar alerta a casos inadequados. Valores recomendados para A, B e C são dentro dos intervalos:
* A: [100, 200]
* B: [0, 1]
* C: [0.5, 2.0]
  
Não é obrigatório que eles estejam dentro dessas margens, porém, concluiu-se experimentalmente que esses intervalos costumam gerar funções e resultados razoáveis.

Além da diferença clara de comportamento da função, outra mudança de grande relevância do modelo alternativo desenvolvido é a forma de distribuição da defluência de Santa Cecília. Na regra da ANA, a mesma apenas irá bombear água uma vez que seu vertimento atinge seu máximo (90 m3/s). Para evitar que água deixe de ser enviada para os demais sistemas, no novo modelo experimentado a distribuição de água é proporcional, mas de maneira ainda coerente com os pontos de máximo e mínimo estabelecidos.

A curva varia também de acordo com a média mensal histórica do reservatório equivalente, ao redor do qual esta é centrada. Na figura abaixo, apresenta-se as funções de defluência para Abril e Novembro, para um mesmo conjunto de parâmetros A, B e C de interesse, são estes (A,B,C) = (190,0.6,2). Nota-se que, como intencionado, a curva em geral encontra-se mais deslocada para direita em meses de cheia, acompanhando a média mensal do reservatório. A partir dessa política, o modelo estará atento também a variações sazonais. Por exemplo, caso o reservatório esteja abaixo da média para um mês de cheia, o sistema entrará em alerta e poderá reduzir sua vazão. Por outro lado, caso esteja acima da média, mesmo em um mês seco, ainda poderá aumentá-la para render geração.

![rep_page](/figures/abril_vs_nov.png)

### Definição da função

Os coeficientes $a, b$ e $c$ da parábola da função é definida resolvendo o sistema de equações linear:

$$
M\times x=b
$$

Onde:

$$
max = max_{hist} - B(max_{hist} - avg_{hist})\\
avg = avg_{hist} - 2 C std_{hist} \\
min = avg_{hist} - (1/2) C std_{hist} 
$$

$$

M = \begin{bmatrix}
max^2 & max^1 & max^0\\
avg^2 & avg^1 & avg^0\\
min^2 & min^1 & min^0
\end{bmatrix}
$$

$$
x = \begin{bmatrix}
a \\
b \\
c
\end{bmatrix}
$$

$$
b = \begin{bmatrix}
250 \\
(250+A)/2 \\
A
\end{bmatrix}
$$

De maneira que adquire-se:

$$
p(x) = ax^2+bx+c
$$

Na qual, $A, B$ e $C$ são os parâmetros mencionados anteriormente, e $max_{hist}$, $avg_{hist}$ e $std_{hist}$ são, respectivamente, o máximo, a média, e o desvio padrão do volume útil do reservatório equivalente da bacia Paraíba do Sul, em (%), no dado mês.

O programa, então, resolve o sistema para cada mês do ano, e define a função de defluência para cada mês $i$ de forma que:

$$
f_i(x) = \begin{cases}
250, \ se \ p_i(x) > 250 \ e \ p_i'(x) > 0, \ senão \\
p_i(x), \ se \ p_i(x) > B \ e \ p_i'(x) > 0, \ senão\\
B
\end{cases}
$$

## Execução

O simulador de regras alternativas utiliza o mesmo ambiente e versionamento do que o de regras da ANA. Instruções detalhadas de como realizar as instalações necessárias e preparar o projeto podem ser encontradas na página do simulador original de regras ANA. Uma vez que as dependências e a pasta do projeto estejam prontas, e o terminal de comando aberto, o simulador pode ser executado pelos comandos:

```
C:\> cd C:\OptimizerParaibaDoSul.jl-master
```

Em seguida, digite o comando abaixo e aperte `Enter` (tenha certeza que nenhum dos arquivos que será editado pelo programa esteja aberto, isto é, arquivos da pasta `results`):

```
julia --project run.jl "function_trials"
```

## Resultados

