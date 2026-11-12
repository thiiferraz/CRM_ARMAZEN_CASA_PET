<?php
require_once 'Pessoa.php';

class Cliente extends Pessoa {
    private $cpfCnpj;
    private $endereco;
    private $perfilId;

    public function __construct($nome, $email, $telefone, $cpfCnpj, $endereco, $perfilId = 1, $id = null) {
        parent::__construct($nome, $email, $telefone, $id);
        $this->cpfCnpj = $cpfCnpj;
        $this->endereco = $endereco;
        $this->perfilId = $perfilId;
    }

    public function getCpfCnpj() { return $this->cpfCnpj; }
    public function getEndereco() { return $this->endereco; }
    public function getPerfilId() { return $this->perfilId; }

    // Polimorfismo: comportamento específico para Cliente/Tutor
    public function exibirResumoPerfil(): string {
        return "[CLIENTE / TUTOR] Nome: {$this->nome} | CPF/CNPJ: {$this->cpfCnpj} | Tel: {$this->telefone} | Endereço: {$this->endereco}";
    }
}