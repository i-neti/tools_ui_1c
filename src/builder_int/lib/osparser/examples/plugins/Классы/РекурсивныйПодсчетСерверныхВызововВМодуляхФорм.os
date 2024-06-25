﻿
 // Рекурсивный подсчет серверных вызовов в модулях форм.
 // Выводятся только случаи с количеством серверных вызовов > 1.

 // Вызовы других модулей не учитываются.
 // Вызовы типа Таблица.НайтиСтроки() не учитываются.

Перем Типы;
Перем Директивы;
Перем Результат;

Перем Вызывающий, ВызывающийНаКлиенте;
Перем ТаблицаВызовов;
Перем Методы;
Перем Стек;

Процедура Открыть(Парсер, Параметры) Экспорт
	Типы = Парсер.Типы();
	Директивы = Парсер.Директивы();
	Результат = Новый Массив;
	ТаблицаВызовов = Новый ТаблицаЗначений;
	ТаблицаВызовов.Колонки.Добавить("Вызывающий");
	ТаблицаВызовов.Колонки.Добавить("НаКлиенте", Новый ОписаниеТипов("Булево"));
	ТаблицаВызовов.Колонки.Добавить("Метод");
	ТаблицаВызовов.Колонки.Добавить("ВызовСервера", Новый ОписаниеТипов("Число"));
	ТаблицаВызовов.Indexes.Добавить("Метод, НаКлиенте");
	Стек = Новый Соответствие;
	Методы = Новый Соответствие;
КонецПроцедуры // Открыть()

Функция Подписки() Экспорт
	Перем Подписки;
	Подписки = Новый Массив;
	Подписки.Добавить("ПосетитьОбъявлениеМетода");
	Подписки.Добавить("ПосетитьВыражениеИдентификатор");
	Возврат Подписки;
КонецФункции // Подписки()

Процедура ПосетитьОбъявлениеМетода(ОбъявлениеМетода) Экспорт
	Вызывающий = ОбъявлениеМетода.Сигнатура;
	ВызывающийНаКлиенте = (Вызывающий.Директивы.Количество() > 0 И Вызывающий.Директивы[0].Директива = Директивы.НаКлиенте);
КонецПроцедуры // ПосетитьОбъявлениеМетода()

Процедура ПосетитьВыражениеИдентификатор(ВыражениеИдентификатор) Экспорт
	Перем НоваяСтрока, Метод;
	Если ВыражениеИдентификатор.Аргументы <> Неопределено И ВыражениеИдентификатор.Хвост.Количество() = 0 Тогда  // только простые вызовы методов данного модуля
		Метод = ВыражениеИдентификатор.Голова.Объявление;
		Если Метод <> Неопределено // только известные методы
			И Метод.Тип <> Типы.ОбъявлениеГлобальногоМетода Тогда
			НоваяСтрока = ТаблицаВызовов.Добавить();
			НоваяСтрока.Вызывающий = Вызывающий;
			НоваяСтрока.НаКлиенте = ВызывающийНаКлиенте;
			НоваяСтрока.Метод = Метод;
			Методы[Метод] = Истина;
		КонецЕсли;
	КонецЕсли;
КонецПроцедуры // ПосетитьВыражениеИдентификатор()

Функция Закрыть() Экспорт
	Для Каждого Метод Из Методы Цикл
		Если Метод.Ключ.Директивы.Количество() = 0 Или Метод.Ключ.Директивы[0].Директива = Директивы.НаСервере Тогда
			ПодсчитатьВызовыСервера(Метод.Ключ);
		КонецЕсли;
	КонецЦикла;
	ТаблицаВызовов.GroupBy("Вызывающий", "ВызовСервера");
	Для Каждого Строка Из ТаблицаВызовов Цикл
		Если Строка.ВызовСервера > 1 Тогда
			Результат.Добавить(СтрШаблон("Метод `%1()` содержит %2 серверных вызовов", Строка.Вызывающий.Имя, Строка.ВызовСервера));
		КонецЕсли;
	КонецЦикла;
	Возврат СтрСоединить(Результат, Символы.ПС);
КонецФункции // Закрыть()

Процедура ПодсчитатьВызовыСервера(Метод)
	Перем ВызовыНаКлиенте;
	Если Стек[Метод.Имя] <> Неопределено Тогда
		Возврат;
	КонецЕсли; 
	Стек[Метод.Имя] = Истина; 
	ВызовыНаКлиенте = ТаблицаВызовов.НайтиСтроки(Новый Структура("Метод, НаКлиенте", Метод, Истина));
	Для Каждого Строка Из ВызовыНаКлиенте Цикл
		Строка.ВызовСервера = Строка.ВызовСервера + 1;
		ПодсчитатьВызовыСервера(Строка.Вызывающий);
	КонецЦикла;
	Стек[Метод.Имя] = Неопределено;
КонецПроцедуры // ПодсчитатьВызовыСервера()
