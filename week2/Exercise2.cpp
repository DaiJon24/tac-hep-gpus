#include <iostream>
#include <vector>
#include <string>

struct Student {
    std::string name;
    std::string email;
    std::string username;
    std:: string experiment;
};


int main() {

    const Student student1={"DaiJon","daijonjames@umass.edu","DaiJon","ATLAS"};
    const Student student2={"Andrew","Atoler@umass.edu","Atoler","ATLAS"};
    const Student student3={"Julianne","jstarzee@umass.edu","jstarzee","ATLAS"};
    const Student student4={"Walker","walkersundqist@umass.edu","walkersundqist","ATLAS"};

    const std::vector<Student> students = {student1, student2, student3, student4};

    for (const Student& student : students) {
        std::cout << "Name:" << student.name << std::endl<< "\n";
        std::cout << "Email:" << student.email << std::endl<< "\n";
        std::cout << "Username:" << student.username << std::endl<< "\n";
        std::cout << "Experiment:" << student.experiment << std::endl<< "\n";

    }

    return 0;



}