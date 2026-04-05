import '../models/chapter.dart';

final List<Chapter> reportToc = [
  Chapter(id: 'part1', title: 'भाग १ प्रारम्भिक', startPage: 1),
  Chapter(id: 'ch1', title: 'परिच्छेद - १ : परिचय', startPage: 1, sections: [
    Chapter(id: 's1.1', title: '१.१. आयोग गठनको पृष्ठभूमि (BACKGROUND)', startPage: 1),
    Chapter(id: 's1.2', title: '१.२. जियनजेड आन्दोलनको विकासक्रम र नेपालमा प्रभाव', startPage: 2),
  ]),
  Chapter(id: 'ch2', title: 'परिच्छेद - २ : जाँचबुझ आयोगको गठन, काम, कर्तव्य, अधिकार र कार्यविधि', startPage: 16),
  Chapter(id: 'ch3', title: 'परिच्छेद - ३ः तथ्य तथा तथ्याङ्क संकलनमा प्रयोग गरिएका विधिहरु', startPage: 18),
  Chapter(id: 'part2', title: 'भाग-२ जाँचबुझको क्रममा संकलित तथ्य\\तथ्याङ्कहरु', startPage: 22),
  Chapter(id: 'ch4', title: 'परिच्छेद ४: आन्दोलनको क्रममा भएको मानवीय र भौतिक क्षति', startPage: 22, sections: [
    Chapter(id: 's4.1', title: '४.१. मानवीय क्षतिको विवरण', startPage: 22),
    Chapter(id: 's4.2', title: '४.२. भौतिक क्षति', startPage: 27),
  ]),
  Chapter(id: 'ch5', title: 'परिच्छेद - ५: बयान तथा घटना विवरण कागज र सरोकारवालाबाट प्राप्त सुझाव', startPage: 28),
  Chapter(id: 'ch9', title: 'परिच्छेद - ९ : सरकारी निकाय, परिषद तथा समितिका निर्णयहरु', startPage: 490),
  Chapter(id: 'ch10', title: 'परिच्छेद - १० : भौतिक प्रमाण संकलन', startPage: 544),
  Chapter(id: 'ch11', title: 'परिच्छेद - ११ : आयोगमा प्राप्त उजुरी तथा गुनासोहरु', startPage: 557),
  Chapter(id: 'part3', title: 'भाग-३ जाँचबुझको क्रममा सँकलित तथ्य\\तथ्याङ्कहरुको विश्लेषण', startPage: 561),
  Chapter(id: 'ch12', title: 'परिच्छेद-१२ संकलित तथ्य\\तथ्याङ्कहरुको विश्लेषण', startPage: 561),
  Chapter(id: 'part4', title: 'भाग-४ निष्कर्ष (CONCLUSION) तथा राय सिफारिस', startPage: 635),
  Chapter(id: 'ch13', title: 'परिच्छेद-१३ जाँचबुझ आयोगको निष्कर्ष, ठहर र सिफारिस', startPage: 635),
  Chapter(id: 'ch14', title: 'परिच्छेद-१४ शासकीय सुधारका लागि आयोगको सुझाव/सिफारिस', startPage: 734, sections: [
    Chapter(id: 's14.17', title: '१४.१७. सत्य निरुपण तथा मेलमिलाप सम्बन्धी व्यवस्था', startPage: 889),
  ]),
  Chapter(id: 'part5', title: 'भाग — ५ सुझाव कार्यान्वयनको कार्ययोजना', startPage: 891),
  Chapter(id: 'epilogue', title: 'उपसंहार', startPage: 896),
];
