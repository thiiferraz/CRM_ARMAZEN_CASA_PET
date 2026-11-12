<?php
require_once 'Pessoa.php';

class Administrador extends Pessoa {
    private $cargo;
    private $nivelAcesso;

    public function __construct($nome, $email, $telefone, $cargo, $nivelAcesso = "Total", $id = null) {
        parent::__construct($nome, $email, $telefone, $id);
        $this->cargo = $cargo;
        $this->nivelAcesso = $nivelAcesso;
    }

    public function getCargo() { return $this->cargo; }
    public function getNivelAcesso() { return $this->nivelAcesso; }

    // Polimorfismo: comportamento específico para Administrador
    public function exibirResumoPerfil(): string {
        return "[ADMINISTRADOR] Nome: {$this->nome} | Cargo: {$this->cargo} | Permissão: {$this->nivelAcesso}";
    }
}