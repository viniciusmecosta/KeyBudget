# Proteção e recuperação do cofre

Cada usuário tem uma chave aleatória de 32 bytes, persistida em users/{uid}/vault_keys/{keyId}. A configuração está em users/{uid}/vault/config, os metadados da migração em users/{uid}/vault_migrations/{migrationId}, os chunks do backup em users/{uid}/vault_backups/{chunkId} e os checkpoints por item em users/{uid}/vault_items/{itemId}. O Firebase Auth e as regras por proprietário autorizam o acesso; o login recupera a chave sem uma senha adicional. O material não é compartilhado entre contas nem regenerado a cada login.

A chave em cache usa flutter_secure_storage, segregada pelo UID. O cache só é utilizado quando a consulta inicial da configuração falha por indisponibilidade de rede, depois de uma abertura verificada. Chave remota ausente ou inválida não é substituída silenciosamente. Uma configuração remota de recuperação impede o fallback offline. Antes de iniciar, retomar ou desfazer uma migração, a sessão remove o cache e suspende o acesso normal ao cofre. Logout descarta o material da sessão e remove seu cache local. Material descartado não pode voltar a criptografar dados.

## Formatos

O formato novo é kbv2. seguido de um JSON em Base64URL com v, alg, kid, nonce, ct e tag. AES-256-GCM usa nonce aleatório de 12 bytes e tag de 16 bytes. Os dados associados vinculam domínio, versão, algoritmo, keyId, UID, ID original da credencial e campo encrypted_password.

A lixeira mantém o ID original em records[].id. Mover/restaurar uma credencial no mesmo UID preserva esse vínculo. Importações reservam o ID de destino antes de criptografar. Backups portáveis mantêm a senha dentro do envelope criptografado do arquivo e a restauração a criptografa com a chave de destino.

O legado IV:ciphertext usa AES-SIC e PKCS7 do pacote encrypt 5.0.3. O leitor recebe explicitamente o texto da chave antiga; não consulta .env. O campo aplica trim nas bordas, exige 32 caracteres/32 bytes UTF-8 e preserva pontuação, caixa e espaços internos. Não decodifica Base64/hexadecimal nem interpreta sintaxe de dotenv.

O legado não autentica a integridade. Conseguir ler texto não comprova sua correção; a interface exige conferência humana. Uma falha de autenticação do formato novo nunca tenta o leitor antigo como fallback. Erros são exceções tipadas; ERRO_DECRIPT pode ser uma senha legítima.

## Migração

1. Perfil → Incluir chave legada só aparece para uma conta com legado e sem chave versionada/configuração anterior.
2. Testar a chave faz apenas leituras, incluindo documentos sem campos de ordenação e credenciais da lixeira.
3. Qualquer falha impede aplicar. O usuário confere e autoriza explicitamente o conjunto exibido.
4. Uma chave nova é persistida e relida. A opção inicial desaparece; uma operação pendente usa Retomar migração.
5. O backup guarda as imagens originais e as senhas conferidas dentro de um pacote AES-GCM com domínio separado. A chave antiga não é incluída.
6. Chunks de até 128 KiB são gravados e relidos do servidor. O pacote completo é autenticado e comparado ao inventário antes da primeira substituição.
7. Cada documento e seu checkpoint são gravados na mesma transação, após comparar o digest original.
8. A verificação final relê todos os documentos e compara as senhas com o backup antes de marcar ready.

Não há lock distribuído ou protocolo de versões antigas. Cliques duplicados são tratados localmente; mudanças inesperadas no documento são reportadas sem sobrescrita.

## Interrupção e rollback

Antes de verificar o backup, nenhum ciphertext original é substituído. Uma nova tentativa poderá pedir a chave antiga, pois ela não foi persistida.

Após verificar o backup, somente o login e a chave nova são necessários para retomar. Checkpoints remotos evitam repetir alterações já confirmadas, inclusive se o processo terminar logo depois de uma transação.

Uma nova tentativa com a chave legada não pode substituir um backup já verificado. Nesse caso, a operação existente deve ser retomada ou desfeita.

Retomar migração permite continuar ou desfazer. Depois da conclusão, Perfil → Proteção do cofre mantém o acesso ao rollback da migração salva. Desfazer compara o documento com o digest gravado pela migração antes de restaurar sua imagem original. Alterações ou remoções posteriores produzem conflito e são preservadas. Rollback interrompido também é retomável.

O rollback exato retorna ao ciphertext legado. Para ler esse formato, será necessário informar novamente a chave antiga. O backup verificado e a chave nova permanecem disponíveis para converter novamente sem depender da antiga.

Backups da migração e suas chaves não são excluídos automaticamente. O pacote da migração depende da chave do usuário no Firestore; o backup portátil .kbudget continua usando a senha escolhida na exportação.

## Testes

A suíte Flutter cobre autenticação do envelope, formato legado, contas separadas, cache offline, ciclo de sessão, prévia sem gravações, interrupção em cada ponto de gravação da migração e do rollback, backup incompleto ou adulterado, lixeira, 650 credenciais e visibilidade da opção no perfil. Edições autenticam a senha original antes de gravar, inclusive ao alterar somente os demais campos; credenciais sem ID reservado são recusadas.

Os testes de regras usam o projeto demo-keybudget no emulador, sem deploy:

    npm --prefix test/firebase_rules ci
    firebase emulators:exec --project demo-keybudget --only firestore 'npm --prefix test/firebase_rules test'

O teste de integração Flutter web usa Firebase Auth e Firestore emulados:

    firebase emulators:exec --project demo-keybudget --only auth,firestore 'flutter test --platform chrome --dart-define=VAULT_EMULATOR_TESTS=true test/core/security/vault_firestore_emulator_test.dart'

A suíte padrão deixa esse teste de emulador explicitamente desabilitado. Nenhuma chave real é usada nos ensaios.
