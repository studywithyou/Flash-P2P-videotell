package
{
	import fl.controls.Button;
	import fl.controls.Label;
	import fl.controls.List;
	import fl.controls.TextInput;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.Video;
	
	import flash.net.GroupSpecifier;
	import flash.net.NetConnection;
	import flash.net.NetGroup;
	import flash.net.NetStream;
	
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	[SWF(width='1000', height='600')]
	public class MainVideoModule extends Sprite
	{
		public function MainVideoModule():void
		{
			// цепочка GUI начинается отсюда
			// localUserRegistration будет стартовать со ввода имени пользователя, т.е. с roomChoiceGUI
			initP2PConnection();
			loginGUI();
		};
		
		// оставляю открытым, чтобы отправлять данные в PHP-скрипт
		private var nameInput:TextInput = new TextInput();
		
		/**
		 * Реализует GUI входа пользователя в систему под своим именем
		 * Активные объекты: usernameLabel, nameInput, initGUIButton
		 * Активные прослушиватели: nameInputHandler, clickHandler
		 */
		private function loginGUI():void
		{
			// чтобы ничего никуда не съезжало
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.stage.align = StageAlign.TOP_LEFT;
			
			// первый активный объект: usernameLabel
			var usernameLabel:TextField = createLabel(15, 15, 'Имя пользователя: ');
			
			// второй активный объект: nameInput
			this.addChild(nameInput);
			nameInput.x = 150; nameInput.y = 15;
			nameInput.addEventListener(Event.CHANGE, nameInputHandler);
			
			// третий активный объект: initGUIButton
			var initGUIButton:Button = createButton(80, 50, 'Соединиться');
			initGUIButton.addEventListener(MouseEvent.CLICK, clickHandler);
			
			// первый активный прослушиватель: nameInputHandler
			function nameInputHandler(event:Event):void
			{
				initGUIButton.enabled = nameInput.text != '';
			};
			
			// второй активный прослушиватель: clickHandler
			function clickHandler(event:Event):void
			{
				// ничего не удаляется из холста,
				// но элементы становятся неактивными
				nameInput.enabled = false;
				initGUIButton.enabled = false;
				// переходим к основному GUI
				roomChoiceGUI();
			};
		};
		
		/* функция для создания надписи, на ввод: x,y === координаты и text === надпись */
		private function createLabel(X:int, Y:int, text:String):TextField
		{
			var label:TextField = new TextField();
			label.defaultTextFormat = new TextFormat('Times New Roman', 14);
			label.autoSize = TextFieldAutoSize.LEFT;
			label.text = text;
			label.x = X; label.y = Y;
			this.addChild(label);
			return label;
		};
		
		/* функция для создания кнопки, на ввод: x,y === координаты и text === надпись */
		private function createButton(X:int, Y:int, text:String):Button
		{
			var button:Button = new Button();
			button.label = text;
			button.enabled = false;
			button.x = X; button.y = Y;
			this.addChild(button);
			return button;
		};
		
		/* функция для создания листа, на ввод: x,y === координаты и width,height === регулировка ширины и высоты */
		/*private function createList(width:int, height:int, X:int, Y:int):List
		{
			var list:List = new List();
			list.width = width;
			list.height = height;
			list.x = X; list.y = Y;
			return list;
		}; */
		
		// предварительно вызываю их здесь, чтобы обращаться к ним извне GUI
		private var usersList:List = new List();
		private var roomsList:List = new List();
		private var usersInRoomList:List = new List();
		
		
		/**
		 * GUI с двумя объектами List, содержащими списки пользователей
		 * Активные объекты: usersList, roomsList, usersInRoomList, roomChoose
		 * Там, где есть *List, есть и соответствующий ему *ListLabel
		 */
		public function roomChoiceGUI():void
		{
			/* 
			для начала разделим блоки, хотя бля зачем, можно было и в основном GUI всё организовать
			но пох уже, пусть будет так пока что
			*/
			this.graphics.lineStyle(2, 0x999999);
			this.graphics.drawRect(1, 1, this.stage.stageWidth-2, this.stage.stageHeight-2);
			this.graphics.drawRect(1, 1, 280, 80);
			this.graphics.drawRect(1, 1, 280, this.stage.stageWidth-2);
			
			var usersListLabel:TextField = createLabel(280/4, 120, 'Сейчас в сети: ');
			
			//usersList = createList(150, 150, 280/6, 150);
			usersList.width = 150; 
			usersList.height = 150;
			usersList.x = 280/6;
			usersList.y = 150;
			this.addChild(usersList);
			
			var roomsListLabel:TextField = createLabel(280/4, 320, 'Список комнат: ');
			//roomsList:List = createList(125, 150, 15, 360);
			roomsList.width = 125; 
			roomsList.height = 150;
			roomsList.x = 15;
			roomsList.y = 360;
			this.addChild(roomsList);
			
			//usersInRoomList:List = createList(125, 150, 140, 360);
			usersInRoomList.width = 125; 
			usersInRoomList.height = 150;
			usersInRoomList.x = 140;
			usersInRoomList.y = 360;
			this.addChild(usersInRoomList);
			
			
			var roomChoose:Button = createButton(280/4, 540, 'Присоединиться');
			roomChoose.enabled = true;
			
			// все пользователи будут заходить в первую комнату
			var roomHash:String = '7d61168cb53c62a32fff5857b5c9ee43';
			initP2PGroup(roomHash);
			// отныне они обе вызываются отсюда, от одной функции,
			// чтобы смочь передать имя пользователя с первым PHP-запросом и инициализирующий XML-документ со вторым PHP-запросом
			localUserInitiatedData();
			roomChoose.enabled = false;
			
			// если roomsList.selectedIndex <= -1, значит комната из списка ещё не выбрана
			/**roomChoose.addEventListener(MouseEvent.CLICK, function():void
				{
					if (roomsList.selectedIndex > -1)
					{**/
						/** 
						 * нумерация объектов в объекте соответствущих листов начинается не с нуля, а с единицы,
						 * а на само́м листе они начинаются с нуля;
						 * так что таким вот образом мы всё это дело синхронизируем
						 */
						/**var roomIndex:Number = (roomsList.selectedIndex + 1);
						trace('Вы хотите зайти в комнату: '+roomsListData[roomIndex].name);
						// Здесь производится переход к комнате по её идентификатору(НЕ md5-хэш!)
						// На вход: хэш комнаты
						// вызываю её после начальной инициализации XML-документа, чтобы была возможность хэши комнат вытащить
						trace('Инициализируем комнату P2P...');
						// инициализация нэт-группы
						initP2PGroup(roomsListData[roomIndex].hash);
						// комнаты больше переключать нельзя
						roomChoose.enabled = false;
					}
				} 
			); **/
			
			
		};
		
		// на заметку
		/**
		 * Короч надо написать обработчик, который будет проверять на валидность всех пользователей и все комнаты.
		 * Это даст системе возможность 'доправлять' всем только изменившуюся информацию.
		 * Далее по тексту комментария:
		 * Локальный пользователь = просто 'локальный'
		 * Удалённый пользователь = просто 'удалённый'
		 * Функция, обрабатывающая всех пользователей и все комнаты = просто 'обработчик'
		 * Холостые обороты сервера = лишние действия функций, приводящие к ухудшению производительности всей системы
		 *
		 * Есть несколько вариантов запросов.
		 * 1. Локальный пользователь входит в сеть и запрашивает начальную загрузку данных о всех пользователях и о существующих комнатах сети:
		 *    — Запись информации о пользователе в БД;
		 *    — Производится загрузка XML-документа, содержащего всю информацию о пользователях и комнатах.
		 * 		Но это уже сделано, поэтому первым будет:
		 * 
		 * 1. Локальный пользователь выходит из сети:
		 *    — закрывая страницу => 
		 *        — в этом случае весь локальный функционал перестанет работать и...
		 *        — ...и локальный для всех удалённых уходит в оффлайн (timestamp будет меньше текущего времени больше 5 секунд)
		 *    — нажав на кнопку "Выйти из сети" =>
		 *        — в этом случае функция, отвечающая за пинг, должна быть отключена немедленно, а также...
		 *        — ...а также функция, обрабатывающая всех пользователей и все комнаты, загрузит остальным инфу о том, что такой-то пользователь вырубился.
		 * 2. Удаленный пользователь вышел из сети:
		 *    — Функция, обрабатывающая всех пользователей и все комнаты на валидность, загружает всем информацию о том, что удаленный пользоавтель вырубился.
		 * 
		 * Функция, которая будет обрабатывать запросы:
		 *    — 1. Начальная инициализация списка для локального пользователя
		 *    — 2. Вход пользователя в сеть
		 *    — 3. Выход пользователя из сети
		 *    — 4. В комнату зашел пользователь
		 *    — 5. Из комнаты вышел пользователь
		 */
		
		/** 
		 * Реализация p2p: нэтСеть + нэтГруппаГлавнойКомнаты, stratusСервер + ключРазраба
		 * А также: idЛокальногоПира(хэш), p2pGroupSpecifier; 
		 * Для нэт-стрима: локальныйНэтСтрим, локальныйВидеоФрейм; удалённыйВидеоФреймОдин, удалённыйНэтСтримОдин; удалённыйВидеоФреймДва итд.
		 * Почему всё так по-индусски?
		 * Да потому что гладиолус.
		 */ 
		private var p2pConnection:NetConnection;
		private var p2pGroup:NetGroup;
		public static const P2PStratusAddress:String = 'rtmfp://stratus.adobe.com/';
		public static const P2PDeveloperKey:String = 'b6acdb5ce6d6589ee60faa4c-a689bc835606';
		private var p2pLocalPeerId:String = 'whatever';
		private var p2pGroupSpecifier:GroupSpecifier;
		// ------------------------------------
		private var p2pLocalNetStream:NetStream;
		private var p2pLocalVideoFrame:Video;
		//
		private var p2pRemoteNetStream_One:NetStream;
		private var p2pRemoteVideoFrame_One:Video;
		private var p2pRemoteNetStream_Two:NetStream;
		private var p2pRemoteVideoFrame_Two:Video;		
		private var p2pRemoteNetStream_Three:NetStream;
		private var p2pRemoteVideoFrame_Three:Video;
		private var p2pRemoteNetStream_Four:NetStream;
		private var p2pRemoteVideoFrame_Four:Video;
		private var p2pRemoteNetStream_Five:NetStream;
		private var p2pRemoteVideoFrame_Five:Video;
		private var p2pRemoteNetStream_Six:NetStream;
		private var p2pRemoteVideoFrame_Six:Video;
		private var p2pRemoteNetStream_Seven:NetStream;
		private var p2pRemoteVideoFrame_Seven:Video;

		
		
		/** Реализация p2p: сеть **/
		private function initP2PConnection():void
		{
			p2pConnection = new NetConnection();
			p2pConnection.connect(P2PStratusAddress+P2PDeveloperKey);
			// некрасиво получилось, но так легче проследить всю цепочку соединений
			p2pConnection.addEventListener(NetStatusEvent.NET_STATUS, initP2PConnectionHandler);
		};
		
		/** Handler для реализации сетевого соединения **/
		private function initP2PConnectionHandler(event:NetStatusEvent):void
		{
			trace('(P2P): '+event.info.code);
			switch(event.info.code)
			{
				case 'NetConnection.Connect.Success':
					// соединение с p2p сетью установлено, ждём соединения с группой
					// здесь мы initP2PMainGroup() не запускаем, поскольку необходимо для начала хэши загрузить, а они грузятся отдельно от p2p
					break;
				case 'NetGroup.Connect.Success':
					// если пользователь подключился к комнате - то создаём поток для вещания
					onGroupConnect();
					break;
				case 'NetStream.Connect.Success':
					onLocalStreamConnect(p2pLocalNetStream);
					break;
			}
		};
		
		
		/**
		 * Собсна здесь и начинается увлекательное путешествие в страну, сука, шифрования.
		 * — Если комната будет называться по её порядковому номеру, то тогда каждый сможет присоединиться к комнате, даже если она будет скрыта от чужих глаз.
		 * — Если же ссылка будет называться длинной строкой, генерируемой посредством md5(), то тогда можно будет достать md5-строку любой комнаты, используя какой-нибудь WireShark.
		 * 		Но достать ссылку может лишь тот, кто к этой комнате присоединился! А значит, можно будет создать и закрытые комнаты!
		 * — Но опять же существует проблема выгрузки всех md5-хэшей из БД, ведь сгенерировавшись, строка записывается именно туда.
		 * 		Злоумышленник может просто декомпильнуть флешку и дописать код, собирающий md5-хэш любой нужной комнаты.
		 * 		Эта проблема решаема лишь авторизацией на PHP-сервере и на БД, как организовать сиё мероприятие - вопрос ещё тот.
		 */
		
		/**
		 * Первоначально загружается md5 первой комнаты
		 */
		/** Реализация p2p: главная группа **/
		private function initP2PGroup(roomHash:String):void
		{
			// узнаём id-хэш флешки
			p2pLocalPeerId = p2pConnection.nearID;
			
			p2pGroupSpecifier = new GroupSpecifier(roomHash);
			// вещание в комнате включено
			p2pGroupSpecifier.multicastEnabled = true;
			// соединяться друг с другом флешки могут
			p2pGroupSpecifier.serverChannelEnabled = true;
			// в главной комнате сидят все, значит пусть сообщения P2P сети через неё и проходят!
			p2pGroupSpecifier.postingEnabled = true;
			
			p2pGroup = new NetGroup(p2pConnection, p2pGroupSpecifier.groupspecWithAuthorizations());
			p2pGroup.addEventListener(NetStatusEvent.NET_STATUS, p2pGroupHandler);
		};
		
		private function p2pGroupHandler(event:NetStatusEvent):void
		{
			trace('(P2P): '+event.info.code);
			switch(event.info.code)
			{
				case 'NetGroup.Neighbor.Connect':
					// если к комнате подключился ещё кто-то, то используем только P2P для отправления данных о нас другому пользователю
					onNeighborConnect(event.info.peerID, event.info.neighbor);
					break;
				case 'NetGroup.Neighbor.Disconnect':
					// если удалённый отключился, то удаляем его из списка текущих пользователей
					onNeighborDisconnect(event.info.peerID, event.info.neighbor);
					break;
				case 'NetGroup.Posting.Notify':
					// передача объектов в группе от пользователя к пользователю
					onPosting(event.info.message, event.info.messageID);
					break;
				case 'NetGroup.MulticastStream.PublishNotify':
					// в сети обнаружен поток: подключаемся к нему
					if(event.info.name == myVideoName)
					{
						trace('Обнаружен видеопоток(локальный): '+event.info.name);
					} else {
						trace('Обнаружен видеопоток: '+event.info.name);
					}
					createVideoStream(event.info.name);
					break;
				case 'NetGroup.MulticastStream.UnpublishNotify':
					// отключение видеопотока: отключаемся от него
					deleteVideoStream(event.info.name);
					break;
			}
		}
		
		/** Пользователь подключился к группе — создание потока для вещания видеоданных в комнату **/
		private function onGroupConnect():void
		{
			p2pLocalNetStream = new NetStream(p2pConnection, p2pGroupSpecifier.groupspecWithAuthorizations());
		}
		
		// имя локального видеопотока
		private var myVideoName:String;
		
		/** Локальный поток инициализирован, подключаем в него камеру и микрофон и выкладываем поток в сеть **/
		private function onLocalStreamConnect(netStream:NetStream):void
		{
			var localCamera:Camera = Camera.getCamera();
			if (localCamera == null) return;
			localCamera.setMode(160, 120, 15);
			localCamera.setQuality(0, 80);
			p2pLocalNetStream.attachCamera(localCamera);
			p2pLocalNetStream.attachAudio(Microphone.getEnhancedMicrophone());
			
			// этот модуль функции позволяет выводить изображение с камеры локального пользователя (левый верхний фрейм)
			p2pLocalVideoFrame = new Video(160, 120);
			p2pLocalVideoFrame.x = 280+25; p2pLocalVideoFrame.y = 40;
			p2pLocalVideoFrame.attachCamera(localCamera);
			this.addChild(p2pLocalVideoFrame);
			// —————————————————————————————————————————————
			
			var myVideoName:String = 'video_'+localUserHash;
			p2pLocalNetStream.publish(myVideoName);
		}
		
		
		// список всех участников группы
		private var usersInRoomData:Object = {};
		
		/** Кто-то подключился к группе — отправляем информацию о себе другим участникам группы 
		 * Примечание: переменные peerId и neighbor поступают на вход и не используются, и это не ошибка **/
		private function onNeighborConnect(peerId:String, neighbor:String):void
		{
			var message:Object = {};
			message['id'] = localUserId;
			message['name'] = nameInput.text;
			message['room'] = localUserRoom;
			message['callCode'] = 'infoAboutMe';
			message['anticash'] = Math.random();
			p2pGroup.post(message);
		}
		
		/** Кто-то отключился от комнаты — удаляем данные о нём и отключаем его видеофрейм **/
		private function onNeighborDisconnect(peerId:String, neighbor:String):void
		{
			// Пока здесь ничего нет, но в будущем будет, ждите ;)
		}
		
		/** 
		 * Пришло сообщение от группы 
		 * Если код вызова равен 'infoAboutMe', то пользователь принял информацию о другом пользователе
		 * Если код вызова равен 'exit', то пользователь хочет выйти из комнаты
		 * Если код вызова равен '' , то 
		 */
		public function onPosting(message:Object, messageId:String):void
		{
			var remoteId:String = message['id'];
			var remoteName:String = message['name'];
			var remoteRoom:int = message['room'];
			var remoteCallCode:String = message['callCode'];
			
			// пользователь входит в комнату
			if(remoteCallCode == 'infoAboutMe')
			{
				// то заносим его в лист и объект, соотв. листу
				
			}
			// пользователь выходит из комнаты
			if(remoteCallCode == 'exit')
			{
				
			}
		}
		
		/** Массив с потоками(изначально все потоки равны null), также массив инициализированности потока(по умолчанию false) **/
		private var remoteVideoStreams:Array = [null, null, null, null, null, null, null, null, null];
		private var remoteVideoStreamsAvailability:Array = ['false', 'false', 'false', 'false', 'false', 'false', 'false', 'false', 'false'];
		
		/** Поступил видеопоток: воспроизводим его **/
		public function createVideoStream(remoteVideoStream:String):void
		{
			// равен ли поступаемый стрим нашему локальному стриму
			var isVideoStreamAvailable:Boolean = (remoteVideoStream != localUserHash);
			
			// проверяем, записан ли уже стрим в массив
			for(var i:int=1; i<(remoteVideoStreams.length+1); i++)
			{
				// если случайно хотим подключиться к локальному потоку
				if(isVideoStreamAvailable)
				{
					// то сразу же break функции, потому что исходящий поток не должен поступать обратно
					trace('ACHTUNG!!11 \n Обнаружено подключение к локальному потоку данных!');
					break;
				}
				// если поток уже есть в массиве
				if (remoteVideoStreams[i] != null)
				{
					if ((remoteVideoStreams[i] == remoteVideoStream) && isVideoStreamAvailable)
					{
						// то переподключаемся к потоку и останавливаем for-цикл
						trace('Видеопоток уже есть, переподключаемся...');
						var streamAlreadyCreated:Boolean = true;
						var alreadyCreatedFrame:int = i; // к какому фрейму необходимо подключиться
						break;
					}
				}
				// переподключение к потоку
				if (streamAlreadyCreated)
				{
					initVideoStream(remoteVideoStream, alreadyCreatedFrame);
					break;
				}
			}
			// если же в массив ещё не записан входящий поток, то только тогда заносим его в массив
			if(!streamAlreadyCreated)
			{
				for(i=1; i<remoteVideoStreams.length; i++)
				{
					// если в массиве нашлось свободное место, то записываем поток в него
					if(remoteVideoStream[i] == null)
					{
						// запись стрима в массив
						remoteVideoStreams[i] = remoteVideoStream;
						initVideoStream(remoteVideoStream, i);
						break;
					}
				}
			}
			// обнуляем для следующего запуска функции
			streamAlreadyCreated = false;
		}
		
		/** Создание экземпляра фрейма и NetStream для входщего потока **/
		public function initVideoStream(VideoStream:String, VideoStreamId:int):void
		{
			// Проверка на доступность потока:
			// Если поток не создан - создаём его;
			// Если поток уже инициализирован, значит при его остановке останется лишь продолжить воспроизведение.
			if (VideoStreamId == 1)
			{
				if (remoteVideoStreamsAvailability[1] == 'false')
				{
					p2pRemoteNetStream_One = new NetStream(p2pConnection, p2pGroupSpecifier.groupspecWithAuthorizations());
					
					// фрейм 2
					p2pRemoteVideoFrame_One = new Video(160, 120);
					p2pRemoteVideoFrame_One.x = 280+25+160+25; p2pRemoteVideoFrame_One.y = 40;
					p2pRemoteVideoFrame_One.attachNetStream(p2pRemoteNetStream_One);
					this.addChild(p2pRemoteVideoFrame_One);
					p2pRemoteNetStream_One.play(VideoStream);
					remoteVideoStreamsAvailability[1] = 'true';
				}
				else
				{
					p2pRemoteNetStream_One.play(VideoStream);
				}
			}
			else if (VideoStreamId == 2)
			{
				if (remoteVideoStreamsAvailability[2] == 'false')
				{
					p2pRemoteNetStream_Two = new NetStream(p2pConnection, p2pGroupSpecifier.groupspecWithAuthorizations());
					
					// фрейм 3
					p2pRemoteVideoFrame_Two = new Video(160, 120);
					p2pRemoteVideoFrame_Two.x = 280+25+160+25+160+25; p2pRemoteVideoFrame_Two.y = 40;
					p2pRemoteVideoFrame_Two.attachNetStream(p2pRemoteNetStream_Two);
					this.addChild(p2pRemoteVideoFrame_Two);
					p2pRemoteNetStream_Two.play(VideoStream);
					remoteVideoStreamsAvailability[2] = 'true';
				} else {
					p2pRemoteNetStream_Two.play(VideoStream);	
				}
			}
			else if (VideoStreamId == 3)
			{
				if (remoteVideoStreamsAvailability[3] == 'false')
				{
					p2pRemoteNetStream_Three = new NetStream(p2pConnection, p2pGroupSpecifier.groupspecWithAuthorizations());
					
					// фрейм 4
					p2pRemoteVideoFrame_Three = new Video(160, 120);
					p2pRemoteVideoFrame_Three.x = 280+25+160+25+160+25+160+25; p2pRemoteVideoFrame_Three.y = 40;
					p2pRemoteVideoFrame_Three.attachNetStream(p2pRemoteNetStream_Three);
					this.addChild(p2pRemoteVideoFrame_Three);
					p2pRemoteNetStream_Three.play(VideoStream);
					remoteVideoStreamsAvailability[3] = 'true';
				} else {
					p2pRemoteNetStream_Three.play(VideoStream);
				}
			}
			else if (VideoStreamId == 4)
			{
				if (remoteVideoStreamsAvailability[4] == 'false')
				{
					p2pRemoteNetStream_Four = new NetStream(p2pConnection, p2pGroupSpecifier.groupspecWithAuthorizations());
					
					// фрейм 5
					p2pRemoteVideoFrame_Four = new Video(160, 120);
					p2pRemoteVideoFrame_Four.x = 280+25; p2pRemoteVideoFrame_Four.y = 40+120+40;
					p2pRemoteVideoFrame_Four.attachNetStream(p2pRemoteNetStream_Four);
					this.addChild(p2pRemoteVideoFrame_Four);
					p2pRemoteNetStream_Four.play(VideoStream);
					remoteVideoStreamsAvailability[4] = 'true';					
				} else {
					p2pRemoteNetStream_Four.play(VideoStream);
				}
			}			
			else if (VideoStreamId == 5)
			{
				if (remoteVideoStreamsAvailability[5] == 'false')
				{
					p2pRemoteNetStream_Five = new NetStream(p2pConnection, p2pGroupSpecifier.groupspecWithAuthorizations());
					
					// фрейм 6
					p2pRemoteVideoFrame_Five = new Video(160, 120);
					p2pRemoteVideoFrame_Five.x = 280+25+160+25; p2pRemoteVideoFrame_Five.y = 40+120+40;
					p2pRemoteVideoFrame_Five.attachNetStream(p2pRemoteNetStream_Five);
					this.addChild(p2pRemoteVideoFrame_Five);
					p2pRemoteNetStream_Five.play(VideoStream);
					remoteVideoStreamsAvailability[5] = 'true';						
				} else {
					p2pRemoteNetStream_Five.play(VideoStream);
				}
			}			
			else if (VideoStreamId == 6)
			{
				if (remoteVideoStreamsAvailability[6] == 'false')
				{
					p2pRemoteNetStream_Six = new NetStream(p2pConnection, p2pGroupSpecifier.groupspecWithAuthorizations());
					
					// фрейм 7
					p2pRemoteVideoFrame_Six = new Video(160, 120);
					p2pRemoteVideoFrame_Six.x = 280+25+160+25+160+25; p2pRemoteVideoFrame_Six.y = 40+120+40;
					p2pRemoteVideoFrame_Six.attachNetStream(p2pRemoteNetStream_Six);
					this.addChild(p2pRemoteVideoFrame_Six);
					p2pRemoteNetStream_Six.play(VideoStream);
					remoteVideoStreamsAvailability[6] = 'true';						
				} else {
					p2pRemoteNetStream_Six.play(VideoStream);
				}
			}
			else if (VideoStreamId == 7)
			{
				if (remoteVideoStreamsAvailability[7] == 'false')
				{
					p2pRemoteNetStream_Seven = new NetStream(p2pConnection, p2pGroupSpecifier.groupspecWithAuthorizations());
					
					// фрейм 8
					p2pRemoteVideoFrame_Seven = new Video(160, 120);
					p2pRemoteVideoFrame_Seven.x = 280+25+160+25+160+25+160+25; p2pRemoteVideoFrame_Seven.y = 40+120+40;
					p2pRemoteVideoFrame_Seven.attachNetStream(p2pRemoteNetStream_Seven);
					this.addChild(p2pRemoteVideoFrame_Seven);
					p2pRemoteNetStream_Seven.play(VideoStream);
					remoteVideoStreamsAvailability[7] = 'true';					
				} else {
					p2pRemoteNetStream_Seven.play(VideoStream);
				}

			}
		}
		
		/** Поток прервался, закрываем его **/
		public function deleteVideoStream(VideoStream:String):void
		{
			// прогоняем видеопоток по массиву
			for (var i:int=1; i<remoteVideoStreams.length; i++)
			{
				if(VideoStream == remoteVideoStreams[i])
				{
					// если поток найден, то обнуляем его
					remoteVideoStreams[i] == null;
					// и останавливаем его
					closeVideoStream(i);
					break;
				}
			}
		}
		
		/** Закрытие экземпляра NetStream для входящего потока **/
		private function closeVideoStream(VideoStreamId:int):void
		{
			if (VideoStreamId == 1)
			{
				// фрейм 2
				p2pRemoteNetStream_One.play(false);
			}
			else if (VideoStreamId == 2)
			{
				// фрейм 3
				p2pRemoteNetStream_Two.play(false);
			}
			else if (VideoStreamId == 3)
			{
				// фрейм 4
				p2pRemoteNetStream_Three.play(false);
			}
			else if (VideoStreamId == 4)
			{
				// фрейм 5
				p2pRemoteNetStream_Four.play(false);
			}			
			else if (VideoStreamId == 5)
			{
				// фрейм 6
				p2pRemoteNetStream_Five.play(false);
			}			
			else if (VideoStreamId == 6)
			{
				// фрейм 7
				p2pRemoteNetStream_Six.play(false);
			}
			else if (VideoStreamId == 7)
			{
				// фрейм 8
				p2pRemoteNetStream_Seven.play(false);
			}
		}
		
		
		// адрес сервера [estoesmivideo.esy.es / test_flash.local]
		private const SERVER_ADDR:String = new String('http://test_flash.local/server.php');



		
		/**
		 * Запрос 1: 
		 * Локальный пользователь отправляет данные о себе(да какие там, блин, данные; имя он отправляет, лол)
		 * Запрос 2:
		 * Локальный пользователь запрашивает начальную загрузку
		 * Всё обрабатывается в одном запросе
		 * */
		public function localUserInitiatedData():void
		{
			/** trace('Запрос 1 и 2:\nЛокальный пользователь запросил загрузку начальных данных...\n'); **/
			var localUserInitRequest:URLRequest;
			var localUserInitLoader:URLLoader;
			localUserInitRequest = new URLRequest(SERVER_ADDR+'?localUserInitiatedData&localUsername='+nameInput.text);
			localUserInitLoader = new URLLoader();
			localUserInitRequest.method = URLRequestMethod.POST;
			localUserInitLoader.load(localUserInitRequest);
			
			// прослушиватели событий запроса
			localUserInitLoader.addEventListener(Event.COMPLETE, function(e:Event):void
				{
					// поступающие данные хранятся в XML-объекте
					var localUserInitData:XMLList = new XMLList(e.target.data);
					// пункт 2: пользователь производит начальную загрузку
					localUserInit(localUserInitData);
					// комментарий с трейсом
					 trace('Данные для начальной инициализации загружены!\n'); 
					 /** trace('Received data: \n' + localUserInitData); **/ 
				}
			);
			localUserInitLoader.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void
				{
					trace('localUserInitiatedData \n');
					trace('I/O error, возможно сервак отключён или просто заипался отвечать на ваши дурацкие запросы =P \n');
				}
			);
		};
		
		// id(число и хэш) локального пользователя
		private var localUserId:int;
		private var localUserHash:String;
		// номер комнаты локального пользователя
		private var localUserRoom:int;
		private var usersListData:Object = new Object();
		private var roomsListData:Object = new Object();
		//private var usersInRoomListData:Object = new Object();

		
		/** Данные поступили, заносим их в список List и в объекты, соответствующие List-объекту **/
		public function localUserInit(Data:XMLList):void
		{
			// users, rooms... vodka and Putin xD
			
			// если это начальная инициализация
			if(hasOwnProperty(Data.localUser.@id))
			{
				// id(число) локального пользователя
				localUserId = Data.localUser.@id;
				// id(хэш) локального пользователя
				localUserHash = Data.localUser.@hashID;
				// номер комнаты локального пользователя
				localUserRoom = Data.localUser.@room;				
			}
			
			var i:int = 0;
			for each (var thisUser:XML in Data.users.*)
			{
				usersList.addItem({label:thisUser.name.toString(), id:thisUser.@id});
				i++; // это чтобы объект начинался с единицы, так уж точно путаницы не будет
				usersListData[i] = {name:thisUser.name.toString(), id:thisUser.@id, room:thisUser.room.toString(), videoStream:thisUser.videoStream.toString()};
				// комментарий с трейсом
				/** 
				 * trace('usersListData['+i+'].name: '+usersListData[i].name+'\nusersListData['+i+'].id: '+usersListData[i].id+'\n|===============|'); */
			};
			i = 0;
			// загружаем список комнат в список 2.1
			for each (var thisRoom:XML in Data.rooms.*)
			{
				roomsList.addItem({label:thisRoom.name.toString()+' [ '+thisRoom.membersNumber.toString()+' / '+thisRoom.maxMembersNumber.toString()+' ]', id:thisRoom.@id});
				i++;
				roomsListData[i] = {name:thisRoom.name.toString(), id:thisRoom.@id.toString(), number:thisRoom.number.toString(), membersNumber:thisRoom.membersNumber.toString(), maxMembersNumber:thisRoom.maxMembersNumber.toString(), hash:thisRoom.hash.toString()};
				// комментарий с трейсом
				/**
				 * trace('roomsListData['+i+'].name: '+roomsListData[i].name+'\nroomsListData['+i+'].id: '+roomsListData[i].id+'\nroomsListData['+i+'].number: '+roomsListData[i].number+'\nroomsListData['+i+'].membersNumber: '+roomsListData[i].membersNumber+'\nroomsListData['+i+'].maxMembersNumber: '+roomsListData[i].maxMembersNumber+'\n|========================|');
				 */
			};
			i = 0;
		};
		
		/** Локальный пользователь обновляет данные, если они изменились на стороне сервера **/
		public function updatingLocalData():void
		{
			trace('Ожидание обновления данных на сервере...\n');
			var updatingLocalDataRequest:URLRequest;
			var updatingLocalDataLoader:URLLoader;
			updatingLocalDataRequest = new URLRequest(SERVER_ADDR+'?updatingLocalData');
			updatingLocalDataLoader = new URLLoader();
			updatingLocalDataRequest.method = URLRequestMethod.POST;
			updatingLocalDataLoader.load(updatingLocalDataRequest);
			
			// прослушиватели событий запроса
			updatingLocalDataLoader.addEventListener(Event.COMPLETE, function(e:Event):void
				{
					var updatingLocalDataData:String = new String(e.target.data);
					trace('Данные получены \n');
					trace(updatingLocalDataData);
				}
			);
			updatingLocalDataLoader.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void
				{
					trace('updatingLocalData \n');
					trace('I/O error, возможно сервак отключён или просто заипался отвечать на ваши дурацкие запросы =P \n');
				}
			);
		};
		

		
	}
}