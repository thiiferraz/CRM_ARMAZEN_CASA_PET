# CRM - Armazém Casa & Pet

Sistema de gestão de relacionamento com clientes (CRM) e controle de vendas/estoque desenvolvido para o segmento de empório e produtos pet.

## Arquitetura e Tecnologias
- **Banco de Dados:** MySQL 8.0+ (Tabelas relacionais, Views analíticas e Triggers de estoque/vendas)
- **Back-end:** PHP Orientado a Objetos (Herança, Polimorfismo, Coleções em Memória e Padrão DAO com PDO)

## Estrutura da Etapa 05 (POO e Coleções)
- `Pessoa.php`: Superclasse abstrata que centraliza os atributos comuns (`id`, `nome`, `email`, `telefone`).
- `Cliente.php` e `Administrador.php`: Subclasses que herdam de `Pessoa` e aplicam polimorfismo no método `exibirResumoPerfil()`.
- `GerenciadorMemoria.php`: Manipulação de objetos em memória utilizando estruturas do tipo `Set` (garantia de unicidade por CPF) e `List` (sequência indexada de itens de venda).
- `demo_etapa05.php`: Script de demonstração prática da arquitetura POO e coleções.

## Como Executar o Projeto
1. Importe o script `.sql` contido na pasta do projeto no MySQL Workbench ou phpMyAdmin.
2. No terminal, dentro da pasta do projeto, inicie o servidor embutido do PHP:
   php -S localhost:8000
3. Acesse no navegador: `http://localhost:8000/demo_etapa05.php`.