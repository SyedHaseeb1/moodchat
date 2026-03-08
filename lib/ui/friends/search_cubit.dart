import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';

abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}
class SearchLoading extends SearchState {}
class SearchResults extends SearchState {
  final List<UserModel> users;
  const SearchResults(this.users);
  @override
  List<Object?> get props => [users];
}
class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override
  List<Object?> get props => [message];
}

class SearchCubit extends Cubit<SearchState> {
  final ProfileRepository _profileRepository;

  SearchCubit(this._profileRepository) : super(SearchInitial());

  void search(String query) async {
    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());
    try {
      final results = await _profileRepository.searchUsers(query);
      emit(SearchResults(results));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  void clear() => emit(SearchInitial());
}
