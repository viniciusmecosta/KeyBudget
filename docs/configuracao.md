# Configuração local

## Ambiente e Firebase

Use Flutter com Dart `>=3.12.0 <4.0.0`, conforme `pubspec.yaml`. No projeto Firebase, habilite Authentication (e-mail/senha e Google) e Cloud Firestore. Adicione os arquivos correspondentes aos aplicativos cadastrados:

- Android: `android/app/google-services.json`.
- iOS: `ios/Runner/GoogleService-Info.plist`.

Configure os identificadores dos aplicativos e as credenciais de login Google para cada plataforma utilizada.

## Criptografia

O aplicativo carrega `assets/.env`. Defina `ENCRYPTION_KEY` com uma chave própria de 32 bytes; o marcador abaixo deve ser substituído:

```env
ENCRYPTION_KEY=<sua-chave-de-32-bytes>
```

Não publique a chave. Preserve-a para continuar acessando os dados criptografados com ela.

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
