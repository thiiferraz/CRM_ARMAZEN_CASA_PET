<?php
require_once 'Cliente.php';

class GerenciadorMemoria {
    // SET (Conjunto): Garante UNICIDADE de CPF em memória (não aceita duplicados)
    private $conjuntoClientesUnicos = [];

    // LIST (Lista): Mantém a ORDEM SEQUENCIAL de inserção por índice (aceita repetição)
    private $listaItensVenda = [];

    public function adicionarClienteNoSet(Cliente $cliente): string {
        $cpf = $cliente->getCpfCnpj();

        if (isset($this->conjuntoClientesUnicos[$cpf])) {
            return "ERRO (Regra do Set): O CPF {$cpf} ({$cliente->getNome()}) já existe na memória! Duplicado bloqueado.";
        }

        $this->conjuntoClientesUnicos[$cpf] = $cliente;
        return "SUCESSO (Set): Cliente {$cliente->getNome()} adicionado sem duplicidade.";
    }

    public function getClientesUnicos(): array {
        return $this->conjuntoClientesUnicos;
    }

    public function adicionarItemNaLista(string $nomeProduto, float $preco): void {
        $this->listaItensVenda[] = [
            'produto' => $nomeProduto,
            'preco' => $preco
        ];
    }

    public function getListaItensVenda(): array {
        return $this->listaItensVenda;
    }
}