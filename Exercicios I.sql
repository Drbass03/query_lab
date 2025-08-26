DESAFIO 1: "Classificação de Vendas por Desempenho"
Tópico: CASE, IF/ELSE, CTE, JOIN

Cenário:
Uma empresa quer classificar seus vendedores conforme o valor total vendido no mês. Use CASE para categorizar o desempenho com base na soma de vendas:

Até R$ 5.000 → "Ruim"

De R$ 5.001 a R$ 15.000 → "Regular"

Acima de R$ 15.000 → "Excelente"

Objetivo:
Crie uma query que gere o nome do vendedor, total vendido e a classificação de desempenho.

--Resposta:

WITH Totais AS (
  SELECT vnd.nome,
         SUM(v.valor_venda) AS total_vendido
  FROM vendas v
  JOIN vendedores vnd ON vnd.id = v.vendedor_id
  GROUP BY vnd.nome
) -- CTE utilizada para trazer o valor total de vendas de cada vendedor wd


SELECT nome, total_vendido,
       CASE
         WHEN total_vendido <= 5000 THEN 'Ruim'
         WHEN total_vendido BETWEEN 5001 AND 15000 THEN 'Regular'
         ELSE 'Excelente'
       END AS Classificacao
FROM Totais; --Projeção final, incluindo case para criar a coluna de classificação




DESAFIO 2: "Trigger de Auditoria de Atualizações Salariais"
Tópico: TRIGGER, INSERTED, DELETED

Cenário:
O RH deseja auditar todas as alterações salariais feitas na tabela de funcionários. Sempre que o salário for alterado, deve-se registrar:

- ID do funcionário

- Salário anterior

- Novo salário

- Data da alteração

Objetivo:
Crie uma TRIGGER que insira automaticamente essas informações em uma tabela de auditoria.

--Resposta

CREATE TRIGGER TRG_auditSalario ON funcionarios
AFTER UPDATE
AS 
BEGIN 
   INSERT INTO auditoria_salario (
              
          funcionario_id,
          salario_antigo,   
          salario_novo, 
          data_alteracao 
    ) -- insert listando cada campo da tabela de auditoria considerando que no CREATE o campo de ID identity já tenha sido incluído
                            
   SELECT i.id,
         d.salario,
         i.salario,
         GETDATE()
    FROM INSERTED i 
    INNER JOIN DELETED d
    ON i.id = d.id
    WHERE i.salario <> d.salario 
END  -- SELECT para realizar o insert na tabela de auditoria
  


DESAFIO 3: "Função de Cálculo de Comissão"
Tópico: CREATE FUNCTION, CASE

Cenário:
A empresa quer criar uma função que receba o ID do vendedor e retorne o valor de comissão. A comissão é calculada assim:

10% sobre o total vendido até R$ 10.000

15% para valores acima disso

Objetivo:
Crie uma função escalar fn_calcula_comissao(@id INT) que retorna a comissão do vendedor.

--Resposta

CREATE FUNCTION calculo_comissao 
  (@idVendedor INT)
 RETURN DECIMAL (8,2)
AS 
BEGIN  
   
   IF @idVendedor IS NULL
    RETURN 0; -- Este trecho trata caso o valor de entrada da função seja null 

   DECLARE @totalVendido DECIMAL (8,2)
   SELECT @totalVendido = SUM(valor_venda) 
   FROM vendas
   WHERE vendedor_id = @idVendedor -- Logica para setar o total vendido 
    
  SET @totalVendido = ISNULL(@totalVendido, 0) -- Este trecho trata a possibilidade do total vendido seja null 


  DECLARE @comissao DECIMAL (8,2)
  SET @comissao = 
    CASE 
      WHEN @totalVendido <= 10000 THEN (@totalVendido * 0.10)
      ELSE (@totalVendido * 0.15)
    END   -- Logica para setar o valor de comissão uso do CASE para atribuir as condições solicita no exercício
    
  RETURN @comissao
END  



DESAFIO 4: "Lista de Funcionários com Último Cargo"
Tópico: CTE, JOIN, ROW_NUMBER()

Cenário:
A empresa armazena os cargos históricos dos funcionários. Você precisa listar o último cargo de cada funcionário com base na data de início.

Objetivo:
Utilize uma CTE com ROW_NUMBER() para retornar apenas o registro mais recente de cada funcionário.

-- Resposta

WITH cargosFunc AS (

  SELECT f.nome, 
        c.cargo, 
        c.data_inicio,
  ROW_NUMBER () OVER(PARTITION BY f.id ORDER BY c.data_inicio DESC) AS ordem 
  FROM cargos c 
  JOIN funcionarios f 
  ON  f.id = c.funcionario_id 
) -- Este trecho busca os cargos de todos os funcionários, a função ROW_NUMBER enumera por ID e ordena os cargos por data de início

SELECT  
    nome,
    cargo,
    data_inicio 
FROM cargosFunc
WHERE ordem = 1  -- Este trecho faz a projeção dos cargos, incluindo a condição que garante que o cargo listado seja o último cargo exercido



DESAFIO 5: "CTE Recursiva: Hierarquia de Projetos"
Tópico: CTE Recursiva, JOIN

Cenário:
Uma empresa tem projetos que podem conter subprojetos, formando uma hierarquia. Queremos listar todos os níveis da hierarquia a partir de um projeto raiz.

Objetivo:
Dado o ID do projeto raiz = 1, retorne todos os subprojetos em níveis (nível 0 = raiz, nível 1 = filho, etc.)

--Resposta

WITH mainProjects AS (

  SELECT id, 
         nome,
         id_main 
  FROM projetos 
  WHERE id_main IS NULL  -- Nivel raiz, traz todos os projetos raiz cujo id_main é NULL 

UNION ALL 

SELECT p.id, 
       p.nome,
      p.id_main
FROM projetos p
JOIN mainProjects m 
ON m.id = p.id_main 
) -- Junção que projeta todos os subprojetos e o ID do projeto raiz relacionado

SELECT id, nome
FROM mainProjects
ORDER BY id -- SELECT FINAL 



DESAFIO 6 - Cálculo do tempo de serviço
Tópico: CASE, DATEDIFF, lógica condicional

Cenário:
O RH deseja classificar os funcionários de acordo com o tempo de empresa:

Até 1 ano: "Novo"

Entre 1 e 5 anos: "Experiente"

Mais de 5 anos: "Veterano" 

-- Resposta

SELECT nome,   
       data_admissao,   -- select traz o nome dos funcionários e sua data de admissão. 
      CASE
        WHEN DATEDIFF(DAY, data_admissao, GETDATE()) <= 364 THEN ' Novato' 
        WHEN DATEDIFF(YEAR, data_admissao, GETDATE()) BETWEEN 1 AND 5 THEN 'Experiente'  -- O case cria uma nova coluna condicional 
        ELSE 'Veterano'                                                                           
      END as Tempo de Servico
FROM funcionarios 




DESAFIO 7 - Trigger para controle de exclusão
Tópico: TRIGGER, DELETED, controle de histórico

Cenário:
O setor fiscal quer registrar toda exclusão de produtos em uma tabela de log. Cada vez que um produto for deletado, devem ser registrados:

id, nome, categoria e data_exclusao

Objetivo:
Crie uma TRIGGER que armazena os dados excluídos em uma tabela log_exclusao_produtos.

--Resposta

CREATE TRIGGER  TRG_audit_exclusao ON produtos
AFTER DELETE 
AS 
BEGIN  

  INSERT INTO log_exclusao_produtos (

      id_produto,                         
      nome,
      categoria,                 
      data_exclusao  
  )  -- Insert que vai levar os dados para a tabela de log 
   
  SELECT 
      id,
      nome,
      categoria,
      GETDATE()
  FROM DELETED -- Este select busca os dados deletados na tabela virtual DELETED e levar para a tabela de log através do insert into

END 




DESAFIO 8 -  Função de cálculo de bônus
Tópico: CREATE FUNCTION, CASE, cálculo percentual

Cenário:
O financeiro quer uma função que retorne o valor de bônus de um funcionário com base no salário e desempenho.

Desempenho "A": 20% do salário

Desempenho "B": 10%

Qualquer outro: 0%

Objetivo:
Crie uma função escalar fn_calcula_bonus 

--Resposta

CREATE FUNCTION FN_calcular_bonus 
(@salario DECIMAL, @nivel CHAR)  -- Definição do nome e tipo dos parametros de entrada. 
RETURNS DECIMAL (8,2)
AS 

BEGIN 
   IF @nivel IS NULL OR @salario IS NULL -- Controle, caso a entrada seja NULL
     RETURN 0; 


DECLARE @bonus DECIMAL (8,2)  -- Declarção da variável vai retornar o valor do bonûs 
SET @bonus = 
  CASE 
     WHEN UPPER(@nivel) = 'A' THEN (@salario * 0.20) 
     WHEN UPPER(@nivel) = 'B' THEN (@salario * 0.10)
     ELSE 0 -- Else, caso o paramêtro de entrada seja diferente de A ou B
  END 

 RETURN @bonus

END 



DESAFIO 9 - Última movimentação por cliente

Tópico: CTE, ROW_NUMBER, análise de histórico

Cenário:
Queremos saber a última movimentação registrada de cada cliente.

Objetivo:
Liste id_cliente, tipo, data_movimento com a movimentação mais recente de cada um.

-- Resposta


SELECT id_cliente,
       tipo,	 
       data_movimento,
	ROW_NUMBER() OVER(PARTITION BY id_cliente ORDER BY data_movimento DESC) AS ordenacao -- Window Function para separar as movimentação por ID e ordenar por datas DESC
FROM movimentos
WHERE ordenacao = 1 -- Este where garante que somente as movimentações mais recentes sejam projetadas no resultado




DESAFIO 10 - Hierarquia de funcionários
Tópico: CTE Recursiva

Cenário:
Funcionários têm supervisores diretos. Queremos listar a hierarquia a partir de um determinado chefe (ex: ID = 1).

Objetivo:
Liste id, nome, id_supervisor, nível da hierarquia.

--Resposta

WITH gestao AS (
    
  SELECT id,
	 nome,
	 id_supervisor
  FROM funcionarios
  WHERE id_supervisor IS NULL  -- Nível raiz da CTE recursiva, traz somente os supervisores. 

UNION ALL 

SELECT f.id,
       f.nome,
       f.id_supervisor
FROM funcionarios f
JOIN gestao g                 -- Parte final da CTE que faz a junção entre a tabela funcionários e o nivel raiz da CTE que trata filtra apenas os supervisores 
ON g.id_supervisor = f.id 
)

SELECT id, nome
FROM gestao;



DESAFIO 11 -Crie uma função escalar status_cliente que recebe o nome do cliente e retorna:

'Ativo' se o nome começar com as letras de A a M,

'Pendente' se começar com N a Z,

'Desconhecido' se for NULL ou string vazia.

--Resposta

CREATE FUNCTION status_cliente
(@nomeCliente VARCHAR(100))

RETURNS VARCHAR(20)
AS
BEGIN 
  DECLARE @status VARCHAR(20)

  IF @nomeCliente IS NULL OR @nomeCliente = ''
  BEGIN
    SET @status = 'Desconhecido'   -- Este trecho faz o controle caso o parametro de entrada seja invalido. 
  END

  BEGIN
    DECLARE @primeiraLetra CHAR(1)
    SET @primeiraLetra = UPPER(LEFT(@nomeCliente, 1)) -- variável declarada e o valor setado para capturar apenas a primeira letra do nome. 

    IF @primeiraLetra BETWEEN 'A' AND 'M'
      SET @status = 'Ativo'
    ELSE IF @primeiraLetra BETWEEN 'N' AND 'Z'
      SET @status = 'Pendente'
    ELSE
      SET @status = 'Caractere invalido'   -- Blocos de IF e ELSE que determina o status de acordo com a primeira letra do nome. 
  END

  RETURN @status
END



Desafio 12 - Marcar produtos premium

Crie uma procedure marcar_produtos_premium que atualiza os produtos com preço acima de R$ 1.000 para a categoria 'Premium'.

--Resposta

CREATE PROCEDURE produtos_premium (@idProduto INT) -- Definição do parametro de entrada e o tipo de dado. 

BEGIN  
  
  BEGIN TRY
    BEGIN TRAN 
      
      UPDATE produtos
      SET categoria = 
        CASE 
          WHEN preco > 1000 THEN 'Premium'
          ELSE 'Normal'
        END
      WHERE id_produto = @idProduto  
    
    COMMIT -- Identificando o valor do produto e alterando a categoria. 
  
  END TRY

  BEGIN CATCH 
    ROLLBACK;
    THROW;   -- Caso ocorra algum erro a transação é cancelada e revertida. 
  END CATCH

END


Desafio 14 - Classificação de parcelas
Crie uma procedure que atualize uma nova coluna chamada status_parcela com:

'Vencida' se a data for menor que hoje,

'A vencer' se estiver nos próximos 30 dias,

'Futura' se estiver além disso.

-- Resposta

CREATE PROCEDURE status_parcela 
AS 
BEGIN
  BEGIN TRY
    BEGIN TRAN

    UPDATE parcelas 
    SET status_parcela = 
      CASE 
        WHEN data_vencimento < GETDATE() THEN 'Vencida'
        WHEN DATEDIFF(DAY(GETDATE(), data_vencimento)) <= 30 THEN 'A vencer'
        ELSE 'Futura'
      END;

    COMMIT
  END TRY

  BEGIN CATCH
    ROLLBACK;
    THROW;
  END CATCH 
END 
    

Desafio 15: Detalhamento de Vendas com Ranking por Mês
Crie uma query que utilize CTE e RANK() para listar os 3 produtos mais vendidos por mês com base na soma de quantidade em uma tabela vendas.
Exiba: mês, id_produto, total_vendido, e a posição no ranking.


-- Resposta


WITH vendasAgrupadas AS (

    SELECT id_produto, 
           FORMAT(data_venda, 'MM') AS mes_venda,
           SUM(quantidade) AS total_vendido
    FROM vendas
    GROUP BY id_produto, FORMAT(data_venda, 'MM')

) 

topVendas AS (

  SELECT mes_venda, 
        id_produto,
        total_vendido
        RANK() OVER(PARTITION BY mes_venda ORDER BY total_vendido) as rank
  FROM vendasAgrupadas
)

SELECT mes_venda, 
       id_produto,
       total_vendido,
       rank 
FROM topVendas
WHERE rank <= 3 
ORDER BY mes_venda, rank



Desafio 16: Função de Calcular Faixa Etária
Crie uma função escalar chamada calcular_faixa_etaria(@data_nascimento DATE) que retorne:

'Criança' se idade < 12

'Adolescente' se idade entre 12 e 17

'Adulto' se idade entre 18 e 64

'Idoso' se idade >= 65

Use funções de data para calcular a idade com precisão.


CREATE FUNCTION fnc_faixa_etaria 
  (@dataNascimento DATE)
RETURNS VARCHAR (15)
AS 
BEGIN 

  DECLARE @faixa_etaria VARCHAR (15)
  SET @faixa_etaria = 
    CASE 
      WHEN DATEDIFF(YEAR,@dataNascimento, GETDATE()) < 12 THEN 'Criança'
      WHEN DATEDIFF(YEAR,@dataNascimento, GETDATE()) BETWEEN 12 AND 17 THEN 'Adolescente'
      WHEN DATEDIFF(YEAR,@dataNascimento, GETDATE()) BETWEEN 18 AND 64 THEN 'Adulto'
      ELSE 'Idoso'
    END

  RETURN @faixa_etaria 

END 



Desafio 17: Função para Padronizar Telefones
Crie uma função escalar chamada padronizar_telefone(@telefone VARCHAR) que:

Remove qualquer caractere que não seja número

Adiciona parênteses e hífen para formatar como (XX) XXXXX-XXXX

Ex: Entrada: '31999991234' → Saída: (31) 99999-1234

--Resposta

CREATE FUNCTION fnc_padronizar_contato 
  (@telefone VARCHAR(11))
RETURNS VARCHAR (11)
AS 
BEGIN 

  DECLARE @nm_formatado VARCHAR(15)
  SET = CONCAT(
            '(',LEFT(@telefone,2),')', -- LEFT add parenteses entre o os dois primeiros caracteres
             SUBSTRING(@telefone,3,5), '-', -- substring extrai do terceiro caractere até o setimo e concatena com o - 
             RIGTH(@telefone,4))  -- os quatros ultimos caracteres também são concatenados com o -
          
RETURN @nm_formatado

END




Desafio 18: Atualizar Limite de Crédito com Base em Compras
Crie uma stored procedure chamada atualizar_limite_credito que recebe como parâmetro o ID de um cliente. Essa procedure deve:

-Calcular o valor médio das compras do cliente nos últimos 6 meses.

-Se a média for maior que R$ 1000, aumentar o limite de crédito do cliente em 10%.

-Se a média for menor ou igual a R$ 1000, manter o limite atual.

-Utilizar JOIN para conectar os dados de clientes e compras.

-Utilizar funções matemáticas como AVG, ROUND, etc.

--Resposta


CREATE PROCEDURE atualizar_limite_credito  (@idCliente INT)
AS 
BEGIN 
  BEGIN TRY 

    BEGIN TRAN  

       WITH mediaCompras AS (

        SELECT id_cliente, ROUND(AVG(c.valor),2) as media_compra 
        FROM compras c
        JOIN clientes p 
        ON c.id_cliente = p.id_cliente
        WHERE c.id_cliente = @idCliente 
          AND  data_compra >= DATEADD(MONTH, -6, GETDATE())
        GROUP BY p.id_cliente -- CTE para trazer o valor médio de compra de cada cliente. 
      ) 

    UPDATE clientes c
    SET limite_credito = 
      CASE 
        WHEN media_compra > 1000 THEN limite_credito + (limite_credito * 0.10) -- CASE para verificar se o limite de compra atende as condições para a liberação de limite
        ELSE limite_credito
      END 
    FROM clientes c
    JOIN mediaCompras m 
    ON c.id_cliente = m.id_cliente 
    WHERE c.id_cliente = @idCliente   
  
  COMMIT 
  END TRY

  BEGIN CATCH 
    ROLLBACK;
    THROW;
  END CATCH

END 

Desafio 19: Trigger de Validação de E-mails de Contato
Contexto: Sua base de dados possui uma tabela de clientes e uma tabela de contatos vinculados a eles.
Alguns e-mails estão mal formatados, e seu trabalho é criar uma trigger que valide e padronize os e-mails no momento da inserção.

A trigger deve:

1-Validar o campo email do novo contato:

2-O e-mail deve conter o caractere '@' e terminar com um domínio válido (.com, .org ou .net).

Caso inválido, lance erro com THROW.

3-Padronizar o e-mail com LOWER(email) antes de salvar.

A trigger deve funcionar corretamente mesmo quando múltiplos registros forem inseridos de uma vez.


CREATE TRIGGER TGR_padronizar_ctt on contatos
AFTER UPDATE, INSERT 
AS 
BEGIN 
  SET NOCOUNT 

  IF EXISTS ( 

    SELECT 1 
    FROM INSERTED 
    WHERE CHARINDEX('@', LOWER(email)) < 1   -- Este bloco localiza emails mal formatados na inserção ou alteraçao, 
      OR RIGHT(LOWER(email),4) <> '.com'
  )
  
  BEGIN 

  THROW 50001, 'Email invalido detectado na inserção ou atualização', 1;

  END 
   
END 


Desafio 20: Avaliação de Gasto Médio por Especialidade

Cenário:
Em uma clínica médica, o gestor deseja identificar pacientes que consultaram em determinada especialidade nos últimos 6 meses e calcular 
o gasto médio por paciente nessa especialidade. Se o gasto médio do paciente for superior a R$ 500, o sistema deve registrar 
isso atualizando uma coluna status_vip da tabela pacientes como 'VIP'.

CREATE PROCEDURE atualizar_status_vip_por_especialidade
  @especialidade VARCHAR(30)- Definição do parametro de entrada
AS
BEGIN
  BEGIN TRY
    BEGIN TRAN;
    
    WITH gastoMedio AS (
      SELECT 
          c.id_paciente,
          ROUND(AVG(c.valor_consulta), 2) AS valor_medio
      FROM consultas c
      JOIN medicos m ON c.id_medico = m.id_medico
      WHERE m.especialidade = @especialidade
        AND c.data_consulta >= DATEADD(MONTH, -6, GETDATE()) 
      GROUP BY c.id_paciente
    ) -- CTE para armazenar os gastos médios de cada paciente 

    UPDATE p
    SET p.status_vip = 
      CASE 
        WHEN g.valor_medio > 500 THEN 'VIP'
        ELSE p.status_vip  
      END
    FROM pacientes p
    JOIN gastoMedio g ON p.id_paciente = g.id_paciente;  -- Este bloco atualiza a coluna status vip de acordo com a condição indicada no CASE 

    COMMIT;
  END TRY
  BEGIN CATCH
    ROLLBACK;
    THROW;
  END CATCH
END


DESAFIO 21: Ranking de Consultas por Paciente e Última Especialidade Visitada

Objetivo:
Criar uma consulta que exiba, para cada paciente:

-A última especialidade médica consultada.

-O ranking de valor de consulta por especialidade (do maior para o menor), por paciente.

-A diferença entre a consulta mais cara e a mais barata.

Usar OUTER APPLY ou CROSS APPLY, funções escalares ou inline, e pelo menos uma função de janela (RANK, ROW_NUMBER, LAG, etc).

--Resposta 

CREATE FUNCTION fnc_calc_diferenca
(@idPaciente INT) 
RETURNS DECIMAL
AS 

BEGIN 

  DECLARE @maior_valor DECIMAL(8,2)
  DECLARE @menor_valor DECIMAL(8,2)
  
  SELECT 
      @maior_valor = MAX(valor_consulta),
      @menor_valor = MIN(valor_consulta)
  FROM consultas 
  WHERE id_paciente = @idPaciente
  
  
  DECLARE @valorDIF DECIMAL (8,2)
  SET @valorDIF = ISNULL(@maior_valor,0) -  ISNULL(@menor_valor,0)

RETURN @valorDIF

END 


SELECT p.id_paciente,
       p.nome,
       m.especialidade,
       c.valor_consulta,
       c.data_consulta,
       RANK() OVER(PARTITION BY id_paciente, especialidade ORDER BY valor_consulta DESC) AS Rank_valor_consulta,
       dbo.fnc_calc_diferenca(p.id_paciente) AS diferenca_valores,
        ultima_consulta.especialidade AS ultima_especialidade,
        ultima_consulta.data_consulta AS data_ultima_consulta

FROM paciente P 
JOIN consulta c
  ON  p.id_paciente = c.id_paciente 
JOIN medicos m 
  ON m.id_medico = c.id_medico
 
OUTER APPLY (
    SELECT TOP 1 c2.data_consulta, m2.especialidade
    FROM consulta c2
    JOIN medicos m2 ON c2.id_medico = m2.id_medico
    WHERE c2.id_paciente = p.id_paciente
    ORDER BY c2.data_consulta DESC
) AS ultima_consulta




Desafio 22 - Tentativa de Pagamento com Reprocessamento em Caso de Falha
Cenário:
Você está em um sistema de gestão de clínica médica. A clínica tenta cobrar um paciente inadimplente por até 3 vezes. 
Se a cobrança não for concluída após 3 tentativas, o paciente será marcado como "Cobrança Manual".

Crie uma procedure que tente atualizar o status de pagamento do paciente em aberto.

A cada tentativa, registre na tabela log_cobranca o resultado.

Se falhar, repita com WHILE até 3 tentativas.

Ao exceder as tentativas, atualize o paciente com status 'Cobrança Manual'.

CREATE TABLE log_cobranca (
    id INT IDENTITY PRIMARY KEY,
    id_paciente INT,
    tentativa INT,
    status_cobranca VARCHAR(20),
    data_tentativa DATETIME DEFAULT GETDATE()
);

CREATE PROCEDURE check_pgto 
  (@id_paciente INT)
AS 
BEGIN 
  
  DECLARE @tentativa INT = 0;
  DECLARE @pagamento BIT = 0; 
  DECLARE @status VARCHAR (10)

 

    
    WHILE @tentativa < 3 
    BEGIN 
      SET @tentativa += 1; 

      
      BEGIN TRY 
         
        IF @pagamento = 1 
        BEGIN 

          SET @status = 'Sucesso'; 

          INSERT INTO log_cobranca VALUES (
            @id_paciente, @tentativa, @status
          )

          BREAK
        END 


        ELSE 
        BEGIN   
          
          SET @status = 'Cobrança Manual'; 

          INSERT INTO log_cobranca VALUES (
            @id_paciente, @tentativa, @status
          )

          THROW 50001, 'Não foi possível processar o pagamento',1 
        END ELSE 
      
      END TRY
       
END 




  
  
  
  











 