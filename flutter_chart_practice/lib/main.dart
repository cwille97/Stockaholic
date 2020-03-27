import 'dart:async';
import 'dart:convert';

import 'secret.dart'; // api key

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:syncfusion_flutter_charts/charts.dart'; // charts

final _formKey = GlobalKey<FormState>(); // global key for our input for Stock symbol
String symbol = '';
List globalStockList;
String dropdownValue = '';
String chartLabel = '';



Future<StockList> fetchStock(String symbol) async { // this method fetches our data from the API
  // a future is a Dart class for async operations, a future represents a potential value OR error that will be available at some future time
  final response = await http.get('https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=' + symbol + '&apikey=' + key); // network request
  // await http.get('https://jsonplaceholder.typicode.com/albums/1');

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return StockList.fromJson(json.decode(response.body)); // get the data
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load stock');
  }
}

class Stock {
  final String date;
  final String open;
  final String high;
  final String low;
  final String close;
  final String volume;

  Stock({this.date, this.open, this.high, this.low, this.close, this.volume});

  @override
  String toString() {
    return 'Date: ' + this.date + ' Open: ' + this.open + ' High: ' + this.high + ' Low: ' + this.low + ' Close: ' + this.close + ' Volume: ' + this.volume;
  }
}

class StockList { // this object is just a list of stocks
  final List list;

  StockList({this.list});

  factory StockList.fromJson(Map<String, dynamic> json) { // parse the json into data we can use it
    if (json['Time Series (Daily)'] == null) {
      throw Exception("An error has occured. Are you sure you entered a valid stock ticker?");
    }
    int size = json['Time Series (Daily)'].keys.toList().length;

    List<Stock> stockList = [];

    for (int i = 0; i < size; i++) {
      stockList.add(new Stock(
        date: json['Time Series (Daily)'].keys.toList()[i],
        open: json['Time Series (Daily)'].values.toList()[i]['1. open'],
        high: json['Time Series (Daily)'].values.toList()[i]['2. high'],
        low: json['Time Series (Daily)'].values.toList()[i]['3. low'],
        close: json['Time Series (Daily)'].values.toList()[i]['4. close'],
        volume: json['Time Series (Daily)'].values.toList()[i]['5. volume'],
      ));
    }
    return StockList(
      list: stockList,
    );
  }
}

void main() => runApp(MaterialApp( // Our app starts off on a simple Stateless home screen
  title: 'Home Screen',
  home: HomeScreen(),
));

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
      body: Center(
        child: Center(
          child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  RaisedButton(
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        // process data
                        Navigator.push(
                          context, // Flutter navigation https://flutter.dev/docs/cookbook/navigation/navigation-basics
                          MaterialPageRoute(builder: (context) => MyApp())
                        );
                      }
                    },
                    child: Text('Load results'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'MSFT',
                      labelText: 'Enter a stock symbol'
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter some text';
                      }
                      else {
                        symbol = value;
                        return null;
                      }
                    },
                  ),
                  Center(
                    child: Row(
                      children: <Widget>[
                        Text(
                            "Adjust value: "
                        ),
                        DropdownButton<String>(
                          icon: Icon(Icons.details),
                          iconSize: 24,
                          items: <String>['Open', 'Close', 'High', 'Low', 'Volume'].map((String value) {

                            return new DropdownMenuItem<String>(
                                value: value,
                                child: new Text(value)
                            );
                          }).toList(),
                          onChanged: (String value) {
                            dropdownValue = value;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              )


          ),
        ),
      ),
    );
  }
}

class _MyAppState extends State<MyApp> {

  Future<StockList> futureStock; // create data object

  @override
  void initState() {
    super.initState();
    futureStock = fetchStock(symbol); // populate the object with data from the API
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stockaholic',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Display Stock Data'),
        ),
        body: Column(
          children: <Widget>[
            Center(
              child: Text(symbol),
            ),
            Center(
              child: RaisedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Go Back!'),
              ),
            ),
            Center(
              child: FutureBuilder<StockList>( // a FutureBuilder is a Widget that builds itself based on the last interaction with a future
                future: futureStock, // future object
                builder: (context, snapshot) { // follow some build strategy
                  if (snapshot.hasData) {
                    globalStockList = snapshot.data.list;
                    return Column(
                      children: <Widget>[
                        SizedBox(
                          height: 400,
                          child: ListView.builder( // see: https://medium.com/@dev.n/the-complete-flutter-series-article-3-lists-and-grids-in-flutter-b20d1a393e39
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemBuilder: (context, position) { // sort of like a for loop with position as variable
                              return Card(
                                child: Text(snapshot.data.list[position].toString()),
                              );
                            },
                            itemCount: snapshot.data.list.length, // loop over entire length
                          ),
                        ),
                        SizedBox(
                          height: 400,
                          child: SfCartesianChart( // chart library: https://pub.dev/packages/syncfusion_flutter_charts
                            primaryXAxis: CategoryAxis(),
                            borderColor: Colors.red,
                            borderWidth: 2,
                            // Sets 15 logical pixels as margin for all the 4 sides.
                            margin: EdgeInsets.all(15),
                            title: ChartTitle(text: dropdownValue + ' prices on dates'),
                            series: <LineSeries<Stock, String>>[
                              LineSeries<Stock, String>(
                                dataSource: globalStockList,
                                xValueMapper: (Stock stock, _) => stock.date,
                                yValueMapper: (Stock stock, _) {
                                  if (dropdownValue == 'Open') {
                                    return double.parse(stock.open);
                                  }
                                  else if (dropdownValue == 'Close'){
                                    return double.parse(stock.close);
                                  }
                                  else if (dropdownValue == 'High'){
                                    return double.parse(stock.high);
                                  }
                                  else if (dropdownValue == 'Low'){
                                    return double.parse(stock.low);
                                  }
                                  else {
                                    return double.parse(stock.volume);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }

                  // By default, show a loading spinner.
                  return CircularProgressIndicator();
                },
              ),
            ),
          ],
        )
      ),
    );
  }
}
