# Logistic Dashboard
An app to track trucks inside factories

![alt text](http://leodegeus.com/wp-content/uploads/2018/10/carTracker.png)

Com o aplicativo Logistic Tracker buscamos criar uma solução para otimização de rotas de caminhões pra entrega de cargas.

O processo inicia com o abrimento de um aplicativo pelo caminhoneiro, o qual este escolhe todos as docas que o mesmo precisa ir para realizar entregas.

Após, o aplicativo utilizando um servidor criado em swift, localiza os lugares mais adequados, baseando em distancia e lotação das docas. Uma visualização para o servidor foi criada e pode ser visualizada no link a seguir:

[![Logistic Tracker Optimizer](https://i.imgur.com/EtH7a3X.jpg)](https://www.youtube.com/embed/jZqG9dSHPVA "Logistic Tracker Optimizer - Clique para assistir!")

Por fim, insights são recolhidos do aplicativo, os quais são mandados para os fornecedores e os gerentes de fábricas, alguns insights:

- Duração do caminhão na fábrica.
- Duração média dos caminhões em dias/semanas/meses em cada doca.
- Zonas de congestionamento na planta.
- Histórico de docas visitados pelos fornecedores, com durações.
- Histórico da visita do caminhão por coordenadas
- O projeto foi criado por demanda e fábricas brasileiras, que precisavam otimizar o tempo de seus fornecedores internamente nas plantas.

Os aplicativo foram criados em Swift, sendo o aplicativo de servidor sendo hospedado localmente em um dispositivo iOS. Todas as conexões foram realizadas utilizando o serviço Firebase Firestore.
