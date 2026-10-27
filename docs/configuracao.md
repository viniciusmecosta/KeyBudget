# Configuração local

## Ambiente e Firebase

Use Flutter com Dart `>=3.12.0 <4.0.0`, conforme `pubspec.yaml`. No projeto Firebase, habilite Authentication (e-mail/senha e Google) e Cloud Firestore. Adicione os arquivos correspondentes aos aplicativos cadastrados:

- Android: `android/app/google-services.json`.
- iOS: `ios/Runner/GoogleService-Info.plist`.

O pacote Dart é `passfin`, e o nome exibido é PassFin. No Android, **mantenha `com.vinicius.key_budget`** tanto no `applicationId` quanto no namespace. Este é o identificador da instalação legada; trocá-lo instala outro aplicativo, sem acesso automático ao armazenamento privado do anterior.

Use o mesmo projeto Firebase e o cliente Android correspondente a esse identificador. Não edite o `package_name` de `google-services.json` manualmente: use o arquivo gerado pelo Firebase. A mudança de marca não exige outro cadastro Android. O certificado de assinatura da atualização também precisa continuar o mesmo.

A pasta existente do Drive, os formatos de backup e os contextos criptográficos continuam compatíveis. Antes de trocar de aparelho ou reinstalar, sincronize os dados e confira um backup criptografado. A nova marca não exige desinstalar o KeyBudget.

## Criptografia

O cofre gera automaticamente uma chave aleatória de 256 bits por usuário e a persiste em users/{uid}/vault_keys/{keyId}. O login recupera a chave, protegida pelas regras de acesso do proprietário. Não há senha adicional do cofre nem configuração de chave em .env para novas instalações.

As senhas usam AES-256-GCM com versão, identificador de chave e autenticação do UID e do ID da credencial. Login, e-mail, notas e anexos mantêm o tratamento atual.

Para contas antigas, abra **Perfil → Incluir chave legada**. Cole somente o valor efetivo da antiga ENCRYPTION_KEY, com 32 caracteres e 32 bytes UTF-8. Espaços nas bordas são removidos; espaços internos, pontuação e maiúsculas/minúsculas são preservados. A chave antiga é temporária e não é salva.

Teste a chave, confira as senhas e autorize a atualização. O aplicativo salva e relê um backup criptografado antes de substituir qualquer senha, incluindo credenciais na lixeira. A entrada inicial desaparece quando a chave versionada existe. Se houver interrupção, use **Retomar migração**; depois do backup verificado, a retomada dispensa a chave antiga. O rollback preserva o backup e a chave nova.

O arquivo local assets/.env antigo deve ser preservado enquanto você ainda precisar recuperar dados legados; ele não é empacotado pelo aplicativo. Detalhes de recuperação estão no [guia do cofre](engineering/vault-encryption.md).

## Regras do Firestore

As regras abaixo limitam o acesso ao perfil e às subcoleções ao usuário autenticado correspondente, incluindo os históricos aninhados das metas:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, create, update: if request.auth != null
                                && request.auth.uid == userId;
    }
    match /users/{userId}/{collection}/{document=**} {
      allow read, write: if request.auth != null
                        && request.auth.uid == userId;
    }
  }
}
```

## Google Drive

Habilite a Google Drive API no projeto Google Cloud associado e configure o consentimento OAuth. Cadastre os identificadores e certificados exigidos pelo login Google na plataforma de destino.

No aplicativo, abra **Perfil → Google Drive**, conecte a conta e toque em **Verificar conexão**. A verificação consulta a API e informa sucesso, acesso expirado ou falha. Documentos e backups usam a conta conectada; essa conexão é separada da sincronização com Firestore.

## Executar

```bash
flutter pub get
flutter run
```

[Voltar ao README](../README.md)
