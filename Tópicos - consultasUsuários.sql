--TRIGGER para encriptar senha
CREATE OR REPLACE FUNCTION encriptandoSenha() RETURNS TRIGGER AS $$
BEGIN
	new.senha := md5(new.senha);
	return new;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER encriptandoSenhaTrigger
BEFORE INSERT OR UPDATE ON usuarios FOR EACH ROW
EXECUTE FUNCTION encriptandoSenha();

insert into usuarios (username, senha, email) values ('EmiDI', '123456', 'EmiDI@gmail.com');
select * from usuarios;

--TRIGGER para checar se usuário ou email já estão cadastrados
CREATE OR REPLACE FUNCTION checandoUsernameEmail() RETURNS TRIGGER AS $$
BEGIN
	IF EXISTS (SELECT 1 FROM usuarios WHERE username = new.username OR email = new.email) THEN
		RAISE EXCEPTION 'Usuário ou e-mail já cadastrados';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER checandoUsernameEmailTrigger
BEFORE INSERT ON usuarios FOR EACH ROW
EXECUTE FUNCTION checandoUsernameEmail();

insert into usuarios (username, senha, email) values ('EmiDI', '123', 'Emi@gmail.com');
insert into usuarios (username, senha, email) values ('Alice', '456', 'EmiDI@gmail.com');

-- TRIGGER para validar o email
CREATE OR REPLACE FUNCTION validandoEmail() RETURNS TRIGGER AS $$
BEGIN
	IF new.email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
		return new;
	ELSE
		raise exception 'O email não está em um formato válido';
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER validandoEmailTrigger
BEFORE INSERT OR UPDATE ON usuarios FOR EACH ROW
EXECUTE FUNCTION validandoEmail();

insert into usuarios (username, senha, email) values ('Alice', '123456', 'Algmail.com');


-- Executa o login
CREATE OR REPLACE FUNCTION login(nome varchar(255), senha varchar(255)) returns boolean AS $$
DECLARE
	logado boolean;
	consulta usuarios%rowtype;
BEGIN
	select * from usuarios
	into consulta
	where username = nome;
	
	senha := md5(senha);
	
	if not found then
		raise notice 'Usuário inválido';
		logado = false;
	elsif consulta.senha = senha then
		raise notice 'Bem vindo %', nome;
		logado = true;
	else
		raise notice 'Senha inválida';
		logado = false;
	end if;
	return logado;
END;
$$ LANGUAGE plpgsql;

select login('EmiDI', '123456');
select login('EmiDI', '23478');

--Atualiza informações de um usuário
CREATE OR REPLACE FUNCTION novasInfos(novo varchar(255), nome varchar(255), senha varchar(255), modificar varchar(20)) returns void as $$
DECLARE
	loginExecutado boolean;
	consulta usuarios%rowtype;
BEGIN
	select login(nome, senha)
	into loginExecutado;
	
	if loginExecutado then
		case modificar
		when 'username' then
			for consulta in select * from usuarios loop
				if consulta.username = novo then
					raise notice 'Nome indisponível';
					return;
				end if;
			end loop;
			update usuarios
			set username = novo
			where username = nome;
			raise notice 'Username atualizado com sucesso';
		when 'senha' then
			update usuarios
			set senha = novo
			where username = nome;
			raise notice 'Senha atualizada com sucesso';
		when 'email' then
			for consulta in select * from usuarios loop
				if consulta.email = novo then
					raise notice 'Email indisponível';
					return;
				end if;
			end loop;
			update usuarios
			set email = novo
			where username = nome;
			raise notice 'Email atualizado com sucesso';
		end case;
	else
		raise notice 'As informações fornecidas para login são inválidas';
	end if;
END;
$$ LANGUAGE plpgsql;

select novasInfos('987654', 'EmiDI', '123456', 'senha');
select novasInfos('Alice', 'EmiDI', '123456', 'username');
select novasInfos('alice.com', 'EmiDI', '987654', 'email');

--Apaga uma conta
CREATE OR REPLACE FUNCTION apagarConta(nome varchar(255), senha varchar(255)) returns void AS $$
DECLARE
	loginExecutado boolean;
BEGIN
	select login(nome, senha)
	into loginExecutado;
	
	if loginExecutado then
		delete from usuarios
		where username = nome;
		raise notice 'Conta apagada com sucesso';
	else
		raise notice 'Informações inválidas, impossível concluir a ação';
	end if;
END;
$$ language plpgsql;

select apagarConta('EmiDI', '987654');