# Compatibilidade de Kotlin no Android

Verificado em 23/10/2026: Flutter 3.44.4, AGP 8.11.1, Kotlin 2.2.20 e Gradle 8.14.

O aviso de KGP envolve `firebase_core 4.15.0`, `firebase_auth 6.7.0` e `home_widget 0.10.0`. O código Gradle dessas versões já verifica a versão de AGP e a opção `android.builtInKotlin`: com AGP 8 ou a opção desativada, aplica o plugin Kotlin tradicional. Portanto, a presença do aviso não implica que trocar essas bibliotecas resolveria a configuração atual.

Mantivemos as dependências e as opções `android.builtInKotlin=false` e `android.newDsl=false`. A [documentação do Flutter](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers) exige AGP 9+ para Kotlin integrado e informa que ativá-lo requer Flutter 3.47+. A atualização deve ocorrer como uma migração coordenada do SDK, Gradle, AGP e plugins, com nova validação de autenticação, armazenamento e widgets. Não se deve apenas remover as opções ou suprimir o aviso.

Validação local: testes Flutter, análise estática, `:app:testDebugUnitTest` e APK release. Os testes nativos usam JUnit apenas em `testImplementation`, sem dependência adicional em produção.
