# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StudentsController, type: :controller do
  describe 'without being logged in' do
    subject { controller }

    # TODO: implement session controller
    # it_behaves_like 'LoggedOut'
    describe 'GET' do
      %w(index new create).each do |action|
        it "#{action} redirects to login" do
          get action

          expect(response).to redirect_to('/users/sign_in')
          expect(flash[:alert]).to eql('Para continuar, efetue login ou registre-se.')
        end
      end
    end
  end

  %w(admin non-admin).each do |action|
    describe "with a #{action} user logged in" do
      if action == 'non-admin'
        let(:user) { FactoryGirl.create(:user, admin: false) }
      else
        let(:user) { FactoryGirl.create(:user) }
      end
      before { sign_in user }

      describe 'GET #index' do
        it 'responds successfully with an HTTP 200 status code' do
          get :index

          expect(response).to be_success
          expect(response.status).to eq(200)
        end

        it 'renders the index template' do
          get :index

          expect(response).to render_template('index')
        end

        context 'without params[:search]' do
          it 'assigns @students with all students paginated' do
            get :index

            expected_students = Student.all.page(nil)
            expect(assigns(:students)).to eq(expected_students)
          end
        end

        context 'with params[:search]' do
          it 'assigns @students with students searched for params[:search]' do
            searchable_context = 'search_test'
            get :index, { search: searchable_context }

            expected_students = Student.search(searchable_context).page(nil)
            expect(assigns(:students)).to eq(expected_students)
          end
        end
      end

      describe "GET #show" do
        it "assigns the requested student to @student" do
          student = FactoryGirl.create(:student)
          process :show, method: :get, params: { id: student}
          expect(assigns(:student)).to eql(student)
        end

        it "renders the #show view" do
          process :show, method: :get, params: { id: FactoryGirl.create(:student)}
          expect(response).to render_template(:show)
        end
      end

      describe 'GET #new' do
        before(:each) do
          get :new
        end

        it 'responds successfully with an HTTP 200 status code' do
          expect(response).to be_success
          expect(response.status).to eq(200)
        end

        it 'renders the new template' do
          expect(response).to render_template('new')
        end
      end

      describe 'PUT #update' do
        let!(:student) { FactoryGirl.create :student }
        let(:valid_params) { { responsible: Faker::GameOfThrones.character } }
        let(:invalid_params) { { responsible: nil } }

        context 'with valid params' do
          it 'accepts changes' do
            process :update, method: :put, params: { id: student.id, student: valid_params}
            expect(flash[:success]).to eql('Estudante atualizado com sucesso')
            expect(response).to redirect_to '/students'
          end
        end

        context 'with invalid params' do
          it 'redirect_to new_student_path' do
            put :update, id: student.id, student: invalid_params
            expect(response).to redirect_to(new_student_path)
          end

          it 'adds error to flash[:error]' do
            put :update, id: student.id, student: invalid_params

            student = assigns(:student)

            error_msg = []
            student.errors.full_messages.each do |msg|
              error_msg << "<div>#{msg}</div>"
            end

            expect(flash[:error]).to eq(error_msg.join)
          end
        end
      end

      describe 'POST #create' do
        context "with valid attributes" do
          it 'create a new student' do
            expect{
              process :create, method: :post, params: { student: {name: Faker::StarWars.character, responsible: Faker::StarWars.character, contact_responsible: Faker::Internet.email, date_enrolment: Time.zone.now - 3.month , status: true }}
            }.to change(Student,:count).by(1)
          end

          it "redirects to the Students" do
            process :create, method: :post, params: { student: {name: Faker::StarWars.character, responsible: Faker::StarWars.character, contact_responsible: Faker::Internet.email, date_enrolment: Time.zone.now - 3.month , status: true }}
            expect(response).to redirect_to Student
          end
        end

        context "with invalid attributes" do
          it "does not save the new student" do
            expect{
              process :create, method: :post, params: { student: {name: nil, responsible: nil, contact_responsible: Faker::Internet.email, date_enrolment: Time.zone.now - 3.month , status: true }}
            }.to_not change(Student,:count)
          end

          it "re-renders the new method" do
            process :create, method: :post, params: { student: {name: nil, responsible: nil, contact_responsible: Faker::Internet.email, date_enrolment: Time.zone.now - 3.month , status: true }}

            expect(flash[:error]).to eql('<div>Name não pode ficar em branco</div><div>Responsible não pode ficar em branco</div>')
            expect(response).to redirect_to :new_student
          end
        end
      end

      describe 'DELETE #destroy' do
        let!(:student) { FactoryGirl.create :student }

        context 'successful destroy' do
          it "deletes the student" do
            expect{
              process :destroy, method: :delete, params: { id: student}
            }.to change(Student,:count).by(-1)
          end

          it "redirects to index" do
            process :destroy, method: :delete, params: { id: student}
            expect(response).to redirect_to '/students'
            expect(flash[:success]).to eql('Estudante excluído com sucesso')
          end
        end

        context 'unsuccessful destroy' do
          it "adds error to flash[:error]" do
            allow_any_instance_of(Student).to receive(:destroy).and_return(false)

            delete :destroy, { id: student }
            expect(flash[:error]).to eq('Erro ao excluir estudante')
          end

          it "redirects to index" do
            allow_any_instance_of(Student).to receive(:destroy).and_return(false)

            delete :destroy, { id: student }
            expect(response).to redirect_to students_path
          end
        end
      end
    end
  end
end

