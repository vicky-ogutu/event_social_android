package com.example.invyte.ui.event

//@HiltViewModel
//class EventDetailViewModel @Inject constructor(
//    private val eventRepo: EventRepository,
//    private val socketManager: SocketManager
//) : ViewModel() {
//    private val _eventState = MutableStateFlow<EventDetailUiState>(EventDetailUiState.Loading)
//    val eventState: StateFlow<EventDetailUiState> = _eventState.asStateFlow()
//
//    fun loadEvent(eventId: Int) {
//        viewModelScope.launch {
//            _eventState.value = EventDetailUiState.Loading
//            val result = eventRepo.getEvent(eventId)
//            _eventState.value = if (result.isSuccess) {
//                EventDetailUiState.Success(result.getOrNull()!!)
//            } else {
//                EventDetailUiState.Error(result.exceptionOrNull()?.message ?: "Error")
//            }
//        }
//    }
//
//    fun joinEventChat(eventId: Int) {
//        viewModelScope.launch {
//            socketManager.connect()
//            socketManager.joinEvent(eventId)
//        }
//    }
//}