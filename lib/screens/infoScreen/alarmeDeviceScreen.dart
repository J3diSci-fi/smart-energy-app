import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smartenergy_app/api/api_cfg.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:smartenergy_app/services/tbclient_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DeviceAlarme extends StatefulWidget {
  final String device_id;
  final ThingsBoardService thingsBoardService;
  

  DeviceAlarme({required this.device_id,  required this.thingsBoardService});
  @override
  _DeviceAlarmeState createState() => _DeviceAlarmeState();
}

class _DeviceAlarmeState extends State<DeviceAlarme> {
  List<Map<String, dynamic>> _alarmes = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: _buildListView(),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _alarmes.length,
      itemBuilder: (context, index) {
        var alarm = _alarmes[index];
        var nome = alarm['nome'] ?? '';
        var detalhes = alarm['detalhes'] ?? '';
        var status = alarm['status'] ?? '';
        var data = alarm['data'] ?? '';

        // Definindo uma cor padrão
        Color color = Colors.green;
        IconData icon = Icons.check_circle; // Ícone padrão para status "CLEARED_ACK"

        // Verificando o status do alarme
        if (status == "Confirmado") {
          color = Colors.green;
          icon = Icons.check_circle;
        } else {
          color = Colors.red;
          icon = Icons.error;
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3), // Altera a posição da sombra
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(
                icon,
                color: color,
                size: 43.0,
              ),
              title: Text(
                nome,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(detalhes),
                  SizedBox(height: 5),
                  Text(
                    'Status: $status',
                    style: TextStyle(color: color),
                  ),
                  Text('Data: $data'),
                ],
              ),
              onTap: () {
                if (status != "Confirmado") {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Confirmar Alarme"),
                        content: Text("Deseja confirmar este alarme?"),
                        actions: [
                          TextButton(
                            child: Text("Cancelar"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text("Confirmar"),
                            onPressed: () async {
                              Navigator.of(context).pop();
                              _confirmarAlarme(alarm);
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  void confirmar(String id, String token) async {
    await widget.thingsBoardService.renewTokenIfNeeded();
    var url = Uri.parse('https://thingsboard.cloud:443/api/alarm/$id/ack');
    var headers = {
      'accept': 'application/json',
      'X-Authorization': 'Bearer $token',
    };

    var response = await http.post(url, headers: headers);

    if (response.statusCode == 200) {
      print('Confirmado com sucesso');
    } else {
      print('Erro ao confirmar o alarme: ${response.statusCode}');
    }
  }

  void clear(String id, String token) async {
    await widget.thingsBoardService.renewTokenIfNeeded();
    var url = Uri.parse('https://thingsboard.cloud:443/api/alarm/$id/clear');
    var headers = {
      'accept': 'application/json',
      'X-Authorization': 'Bearer $token',
    };

    var response = await http.post(url, headers: headers);

    if (response.statusCode == 200) {
      print('limpou com sucesso');
    } else {
      print('Alarme já foi limpo: ${response.statusCode}');
    }
  }

  void _confirmarAlarme(Map<String, dynamic> alarm) async {
    await widget.thingsBoardService.renewTokenIfNeeded();
    String token = Config.token;
    //confirmar
    confirmar(alarm['id'], token);
    //clear
    clear(alarm['id'], token);

    setState(() {
      alarm['status'] = "Confirmado";
    });
  }

  void fetchData() async {
    await widget.thingsBoardService.renewTokenIfNeeded();
    String id_device = widget.device_id;
    String token = Config.token;
    var url = Uri.parse(
        'https://thingsboard.cloud/api/alarm/DEVICE/$id_device?pageSize=100&page=0&sortProperty=createdTime&sortOrder=DESC');
    var headers = {
      'accept': 'application/json',
      'X-Authorization': 'Bearer $token',
    };

    var response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      var alarms = jsonResponse['data'];
      tz.initializeTimeZones();
      var localTimezone = tz.getLocation('America/Sao_Paulo');
      for (var alarm in alarms) {
        var id = alarm['id']['id'];
        var createdTimeMillis = alarm['createdTime'];
        var details = alarm['details'].toString();
        var status = alarm['status'];
        var name = alarm['originatorName'];
        String novoNome = name.split("-")[0];
        // Ajusta a data e hora em 3 horas para trás
       
        //var dateTime = DateTime.fromMillisecondsSinceEpoch(createdTimeMillis).subtract(Duration(hours: 3));
        var dateTime = tz.TZDateTime.fromMillisecondsSinceEpoch(localTimezone, createdTimeMillis);
        // Formata a data e hora no padrão brasileiro
        var formattedDateTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);

        if (status == "CLEARED_ACK") {
          status = "Confirmado";
        } else {
          status = "Não confirmado";
        }
        setState(() {
          _alarmes.add({
            'nome': novoNome,
            'detalhes': details,
            'status': status,
            'id': id,
            'data': formattedDateTime,
          });
        });
      }
    } else {
      print('Erro: ${response.statusCode}');
    }
  }

  PreferredSizeWidget appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Histórico',
        style: TextStyle(color: Colors.black),
      ),
      iconTheme: IconThemeData(color: Colors.black),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop(true);
        },
      ),
    );
  }
}
