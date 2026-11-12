<?php
require_once 'Cliente.php';
require_once 'Administrador.php';
require_once 'GerenciadorMemoria.php';

echo "<h1>Demonstração Etapa 05 - POO, Herança, Polimorfismo e Coleções</h1>";

echo "<h2>1. Herança e Polimorfismo (Superclasse Pessoa)</h2>";
$admin = new Administrador("Thiago Ferraz", "thiago@armazem.com", "(31) 99999-8888", "Gestor do Empório");
$cliente1 = new Cliente("João Afonso", "joao@email.com", "(31) 98888-7777", "987.654.321-11", "Belo Horizonte - MG");
$clienteDuplicado = new Cliente("João Afonso Clone", "outro@email.com", "(31) 90000-0000", "987.654.321-11", "Contagem - MG");

$pessoas = [$admin, $cliente1];
foreach ($pessoas as $pessoa) {
    echo "<p>" . $pessoa->exibirResumoPerfil() . "</p>";
}

$memoria = new GerenciadorMemoria();

echo "<h2>2. Coleção SET (Unicidade de CPF em Memória)</h2>";
echo "<p style='color:green;'>" . $memoria->adicionarClienteNoSet($cliente1) . "</p>";
echo "<p style='color:red;'>" . $memoria->adicionarClienteNoSet($clienteDuplicado) . "</p>";

echo "<h2>3. Coleção LIST (Sequência Indexada de Itens da Venda)</h2>";
$memoria->adicionarItemNaLista("Ração Quatree Supreme 15kg", 210.00);
$memoria->adicionarItemNaLista("Queijo Artesanal Alagoa", 45.00);
$memoria->adicionarItemNaLista("Queijo Artesanal Alagoa", 45.00);

echo "<ol>";
foreach ($memoria->getListaItensVenda() as $indice => $item) {
    echo "<li>Índice [{$indice}] da Lista: {$item['produto']} - R$ {$item['preco']}</li>";
}
echo "</ol>";