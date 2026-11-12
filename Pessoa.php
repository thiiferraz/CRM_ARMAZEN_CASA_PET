<?php

abstract class Pessoa {
    protected $id;
    protected $nome;
    protected $email;
    protected $telefone;

    public function __construct($nome, $email, $telefone, $id = null) {
        $this->id = $id;
        $this->nome = $nome;
        $this->email = $email;
        $this->telefone = $telefone;
    }

    public function getId() { return $this->id; }
    public function getNome() { return $this->nome; }
    public function getEmail() { return $this->email; }
    public function getTelefone() { return $this->telefone; }

    // Método abstrato que obriga as subclasses a aplicarem Polimorfismo
    abstract public function exibirResumoPerfil(): string;
}   