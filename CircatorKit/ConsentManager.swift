//
//  ConsentManager.swift
//  Circator
//
//  Created by Sihao Lu on 12/19/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import ResearchKit
import Locksmith

public typealias ConsentBlock = ((consented: Bool) -> Void)?

private let ConsentFilePathKey = "CMConsentFileKey"
private let unnamedAccount = "default"

public class ConsentManager: NSObject, ORKTaskViewControllerDelegate {
    private enum Identifier {
        case EligibilityTask

        case EligibilityIntroStep
        case EligibilityFormStep
        case EligibilityQuestionStep
        
        case EligibilityEligibleStep
        case EligibilityIneligibleStep
        
        case EligibilityFormItem01
        case EligibilityFormItem02
        case EligibilityFormItem03
        
        case ConsentDocumentParticipantSignature
        case ConsentDocumentInvestigatorSignature
        case VisualConsentStep
        case ConsentSharingStep
        case ConsentReviewStep
        
        case EligibilityAndConsentTask
        case ConsentTask
    }
    
    public static let sharedManager = ConsentManager()
    
    private var consentHandler: ((consented: Bool) -> Void)?
    
    public var obtainedUserConsent: Bool {
        get {
            if let dictionary = Locksmith.loadDataForUserAccount(unnamedAccount),
                   consented = dictionary["consent"] as? Bool
            {
                return consented
            } else {
                return false
            }
        }
    }
    
    private func setUserConsentObtained(consentObtained: Bool = true) {
        do {
            try Locksmith.saveData(["consent" : consentObtained], forUserAccount: unnamedAccount)
        } catch {
            print("Error: Cannot save to keychain!")
        }
    }
    
    public func getConsentFilePath() -> String? {
        if let dictionary = Locksmith.loadDataForUserAccount(unnamedAccount),
            consentFilePath = dictionary["consentfile"] as? String
        {
            return consentFilePath
        }
        return nil
    }
    
    private func setConsentFilePath(consentFilePath: String) {
        do {
            try Locksmith.updateData(["consent": obtainedUserConsent,
                                      "consentfile": consentFilePath],
                                     forUserAccount: unnamedAccount)
        } catch {
            print("Error: Cannot save to keychain!")
        }
    }
    
    private var welcomeText: String {
        return "This simple walkthrough will explain the research study, the impact it may have on your life and will allow you to provide your consent to participate."
    }
    
    private var welcomeSectionText: String {
        return "We hope to learn the differences in how you navigate your daily tasks; to assess whether mobile devices and sensors can help better measure and manage our lives; and to ultimately improve the quality of life for people.  This study is unique in that it allows participants to step up as equal partners in both the monitoring and the sharing of their aggregate data as well as in the research process and analysis."
    }
    
    private var sensorDataText: String {
        return "This study will also gather sensor data from yor iPhone and personal devices with your permission."
    }
    
    private var dataProcessingText: String {
        return "Your study data (survey and sensors) will be combined with similar data from other participants."
    }
    
    private var protectingYourData: String {
        return "We will replace your name with a random code.  The coded data will be encrypted and stored on a secure Amazon Web Services Database to prevent improper access"
    }
    
    private var dataUse: String {
        return "The data will be used for this research and may be shared with research partners worldwide."
    }
    
    private var withdrawing: String {
        return "Your participation is voluntary.  You may withdraw your consent and discontinue participation at any time."
    }
    
    private var potentialBenefits: String {
        return "You will be able to visualize your data and potentially learn more about trends in your health."
    }
    
    private var issuesToConsider: String {
        return "This research is not a treatment study.  Some questions may make you feel uncomfortable.  Simply do not respond to those questions."
    }
    
    private var riskToPrivacy: String {
        return "We will make every effort to protect your information, but total anonymity cannot be guaranteed"
    }
    
    private var PotentialBenefitsLong: String {
        return "How can we better manage the complexities of metabolic syndrome and the lives of those at risk for having metabolic diseases? We want to understand why some individuals at risk or having been diagnosed with metabolic syndrome recover faster than others, why their symptoms vary over time, and what can be done to make those symptoms improve.  We at Johns Hopkins University are proposing a new approach to allow participants to monitor their health in real time as well as partner in research studies. This app is designed for research and educational purposes only.  You should not rely on this information as a substitute for personal medical attention, diagnosis or hands-on treatment.  If you are concerned about your health or that of a child, please consult your family's health provider immediately.  Do not wait for a response from our professionals."
    }
    
    private var ConsiderLongText: String {
        return "We hope to learn the differences in how people navigate through their days; to assess whether mobile devices and sensors can help better measure and manage metabolic disease and its progression; and to ultimately improve the quality of life for people. We are looking for volunteers to participate in this research study. If you are over 18 years old with a history of metabolic disease or without any history of metabolic disease, but at risk, we invite you to join this study. You do not need to have had metabolic syndrome to join this study."
    }
    
    private var eligibilitySteps: [ORKStep] {
        get {
            // Intro step
            let introStep = ORKInstructionStep(identifier: String(Identifier.EligibilityIntroStep))
            introStep.title = NSLocalizedString("Welcome to Metabolic Compass", comment: "")
            
            // Form step
            let formStep = ORKFormStep(identifier: String(Identifier.EligibilityFormStep))
            formStep.optional = false
            
            // Form items
            let formItem01 = ORKFormItem(identifier: String(Identifier.EligibilityFormItem01), text: "Are you over 18?", answerFormat: ORKAnswerFormat.eligibilityAnswerFormat())
            formItem01.optional = false
            let formItem02 = ORKFormItem(identifier: String(Identifier.EligibilityFormItem02), text: "Do you worry about your diet?", answerFormat: ORKAnswerFormat.eligibilityAnswerFormat())
            formItem02.optional = false
            let formItem03 = ORKFormItem(identifier: String(Identifier.EligibilityFormItem03), text: "Do you live in the United States of America?", answerFormat: ORKAnswerFormat.eligibilityAnswerFormat())
            formItem03.optional = false
            
            formStep.formItems = [
                formItem01,
                formItem02,
                formItem03
            ]
            
            // Ineligible step
            let ineligibleStep = ORKInstructionStep(identifier: String(Identifier.EligibilityIneligibleStep))
            ineligibleStep.title = NSLocalizedString("You are ineligible to join the study", comment: "")
            
            // Eligible step
            let eligibleStep = ORKCompletionStep(identifier: String(Identifier.EligibilityEligibleStep))
            eligibleStep.title = NSLocalizedString("You are eligible to join the study", comment: "")
            
            return [
                introStep,
                formStep,
                ineligibleStep,
                eligibleStep
            ]
        }
    }
    
    private var consentDocument: ORKConsentDocument {
        
        let consentDocument = ORKConsentDocument()
        
        /*
        This is the title of the document, displayed both for review and in
        the generated PDF.
        */
        consentDocument.title = NSLocalizedString("Metabolic Compass", comment: "How can we better understand and manage the problems associated with metabolic syndrome?")
        
        // This is the title of the signature page in the generated document.
        consentDocument.signaturePageTitle = NSLocalizedString("Consent", comment: "")
        
        /*
        This is the line shown on the signature page of the generated document,
        just above the signatures.
        */
        consentDocument.signaturePageContent = NSLocalizedString("I agree to participate in this research study.", comment: "")
        
        /*
        Add the participant signature, which will be filled in during the
        consent review process. This signature initially does not have a
        signature image or a participant name; these are collected during
        the consent review step.
        */
        let participantSignatureTitle = NSLocalizedString("Participant", comment: "")
        let participantSignature = ORKConsentSignature(forPersonWithTitle: participantSignatureTitle, dateFormatString: nil, identifier: String(Identifier.ConsentDocumentParticipantSignature))
        
        consentDocument.addSignature(participantSignature)
        
        /*
        Add the investigator signature. This is pre-populated with the
        investigator's signature image and name, and the date of their
        signature. If you need to specify the date as now, you could generate
        a date string with code here.
        
        This signature is only used for the generated PDF.
        */
        let signatureImage = UIImage(named: "tbw_signature")!
        let investigatorSignatureTitle = NSLocalizedString("Professor", comment: "")
        let investigatorSignatureGivenName = NSLocalizedString("Thomas", comment: "")
        let investigatorSignatureFamilyName = NSLocalizedString("Woolf", comment: "")
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/YY"
        let investigatorSignatureDateString = dateFormatter.stringFromDate(NSDate())
        
        let investigatorSignature = ORKConsentSignature(forPersonWithTitle: investigatorSignatureTitle, dateFormatString: nil, identifier: String(Identifier.ConsentDocumentInvestigatorSignature), givenName: investigatorSignatureGivenName, familyName: investigatorSignatureFamilyName, signatureImage: signatureImage, dateString: investigatorSignatureDateString)
        
        consentDocument.addSignature(investigatorSignature)
        
        /*
        This is the HTML content for the "Learn More" page for each consent
        section. In a real consent, this would be your content, and you would
        have different content for each section.
        
        If your content is just text, you can use the `content` property
        instead of the `htmlContent` property of `ORKConsentSection`.
        */
        let activitiesContentString = "<body><p>We will ask you to:</p><ul><li>Answer an initial questionnaire about your health, exercise, diet, sleep and medicines.</li><li>Rate your fatigue, thinking, sleep, mood and exercise performance on a scale of 1 to 5 daily.</li><li>Track changes by answering a weekly and monthly survey</li><li>Keep a health diary on the app</li></ul><p>We will send notices on your phone asking you to complete these activities and surveys.  You may choose to act at your convenience, (either then or later) and you may choose to participate in all or only in some parts of the study. You may skip any questions that you do not wish to answer.</p></body>"
        
        let sensorDataContentString = "<body><p>You have the option to contribute activity data collected through:</p><ul><li>The sensors on your iPhone or any wearable activity device (like iPhone, iPod, Apple Watch, or third-party device) </li><li>Other applications and data available through Apple Health app.</li></ul><p>You can choose not to provide this data and still participate in the study.</p><p>We will NOT access your personal contacts, personal photos, text or email messages.</p></p></body>"
        
        let dataProcessingString = "<body><p>We will electronically process your data.<br /><br />We will separate your account information (name, email, contact information, etc.) from your study data (your responses to surveys and the measurements from the phone itself when you perform activities).<br /><br />We will combine your coded study data (without your name) with those of other study participants to be analyzed.<br /><br />WE WILL NEVER SELL, RENT OR LEASE YOUR CONTACT INFORMATION. <br /><br /></body>"
        
        let protectingDataString = "<body><p>We will electronically process your data.<br /><br />We will separate your account information (name, email, contact information, etc.) from your study data (your responses to surveys and the measurements from the phone itself when you perform activities).<br /><br />We will combine your coded study data (without your name) with those of other study participants to be analyzed.<br /><br />WE WILL NEVER SELL, RENT OR LEASE YOUR CONTACT INFORMATION. <br /><br /></body>"
        
        let dataUseString = "<body><p>By analyzing the data from all app users, we may be able to better understand how people adjust their activity levels, their eating profiles, and their sleep patterns to achieve optimal health.</p><p>We hope that together we can learn:</p><ul><li>The ways you have found to navigate from poor health to improved health</li><li>To help us assess whether mobile devices and sensors can measure and better understand our own behavior and contribute (in anonymous aggregate) to improving the health of others as well</li><li>Ultimately to improve the quality of life for all those either suffering from or at risk for metabolic disease.</li></ul></body>"
        
        let timeString = "<body><p>We will send notices on your phone asking you to complete these tasks and surveys. You may choose to act at your convenience, either then or later, and you may choose to participate in all or only in some parts of the study.</p><p>Transmitting data collected in this study may count against your existing mobile data plan. You may configure the application to only use WiFi connections to limit the impact this data collection has on your data plan.</p><p>This study should take you about 20 minutes each week.</p></body>"
        
        let yourInsightString = "<body><p>We encourage you to provide insights to the researchers. This study is unique in that it allows you to step up as an equal partner in the research process.</p></body>"
        
        let withDrawingString = "<body><p>Your participation in this study is voluntary. You may decide not to participate or you may leave the study at any time. If you withdraw from the study, we will stop collecting new data, but the coded study data that you have already provided, and that have already been distributed will not be able to be destroyed or deleted.</p><p>To withdraw from this study please contact  Dr. Thomas Woolf by email <a href='mailto:twoolf@jhmi.edu'>twoolf@jhmi.edu</a>  or call <a href='tel:14106142643'>+1-410-614-2643</a> or tap on the 'Leave Study' link in the profile page of the application.</p></body>"
        
        let potentialBenefitsString = "<body><p>The benefits of this study are primarily the creation of insights to help current and future people with metabolic syndrome and their families to better understand and manage their health.</p><p>We will return the insights learned from analysis of the study data through the study website, blogs and/or research publications, but these insights may not be of direct benefit to you. We cannot, and thus we do not, guarantee or promise that you will personally receive any direct benefits from this study. However, you will be able to track your health and export your data at will to share with your medical doctor and anyone you choose.</p></body>"
        
        let issuesSurveyString = "<body><p>This is not a treatment study and we do not expect any medical side effects from participating. </p><p>Some survey questions may make you feel uncomfortable. Know that the information you provide is entirely up to you and you are free to skip questions that you do not want to answer. Other people may glimpse the study notifications and/or reminders on your phone and realize you are enrolled in this study. This can make some people feel self-conscious.</p></body>"
        
        let issuesMoodString = "<body><p>Participating in this study may change how you feel. You may feel tired, sad, energized or happy.</p><p>Participation in this study may involve risks that are not known at this time. You will be told about any new information that might change your decision to be in this study.</p></body>"
        
        let privacyRiskString = "<body><p>Participating in this study may change how you feel. You may feel tired, sad, energized or happy.</p><p>Participation in this study may involve risks that are not known at this time. You will be told about any new information that might change your decision to be in this study.</p></body>"
        
        let sharingResearchString = "<body><p>This study gives you the option to share your data in 2 ways:</p><p><strong>1- Share broadly with the research world:</strong>  You can choose to share your coded study data with qualified researchers worldwide for use in this research and beyond. Coded study data is data that does not include personal information such as your name or email. Qualified researchers are registered users of Synapse who have agreed to use the data in an ethical manner for research purposes, and have agreed to not attempt to re-identify you. If you choose to share your coded study data, the coded data will be added to a shared dataset available to qualified researchers on the Sage Bionetworks Synapse servers. (www.synapse.org). Johns Hopkins University will have no oversight onthe future research that qualified researchers may conduct with the coded study data.</p><p><strong>2- Share with Johns Hopkins University and its partners only:</strong> You can choose to share your study data only with the study team and its partners. The study team includes the sponsor of the research and any other researchers or partners named in the consent document. Sharing your data only with Johns Hopkins means that your data will not be made available to anyone other than those listed inthe consent document and for the purposes of this study only.</p><p>If required by law, your data (study data and account information), and the signed consent form may be disclosed to:</p><ul><li>The US National Institute of health, Department of Health and Human Services agencies, Office for Human Research Protection, and other agencies as required,</li><li>Institutional Review Board who monitors the safety, effectiveness and conduct of the research being conducted,</li><li>Others, if the law requires</li></ul><p>The results of this research study may be presented at meetings or in publications. If the results of this study are made public, only coded study data will be used, that is, your personal information will not be disclosed.</p><p>You can change the data sharing setting though the app preference at anytime.  For additional information review the study website <a href='http://MetabolicCompass.org'>MetabolicCompass.org</a> </p></body>"
        
        /*
        These are all the consent section types that have pre-defined animations
        and images. We use them in this specific order, so we see the available
        animated transitions.
        */
        let consentSectionTypes: [ORKConsentSectionType] = [
            .Overview,
            .DataGathering,
            .Privacy,
            .DataUse,
            .TimeCommitment,
            .StudySurvey,
            .StudyTasks,
            .Withdrawing
        ]
        
        /*
        For each consent section type in `consentSectionTypes`, create an
        `ORKConsentSection` that represents it.
        
        In a real app, you would set specific content for each section.
        */
        var consentSections: [ORKConsentSection] = consentSectionTypes.map { contentSectionType in
            let consentSection = ORKConsentSection(type: contentSectionType)
            
            if contentSectionType == .Overview {
                consentSection.summary = welcomeText
                consentSection.htmlContent = welcomeSectionText
            }
            else if contentSectionType == .DataGathering {
                consentSection.summary = dataProcessingText
                consentSection.htmlContent = sensorDataContentString
            }
            else if contentSectionType == .Privacy {
                consentSection.summary = protectingYourData
                consentSection.htmlContent = protectingDataString
            }
            else if contentSectionType == .DataUse {
                consentSection.summary = dataUse
                consentSection.htmlContent = dataUseString
            }
            else if contentSectionType == .TimeCommitment {
                consentSection.summary = potentialBenefits
                consentSection.htmlContent = PotentialBenefitsLong
            }
            else if contentSectionType == .StudySurvey {
                consentSection.summary = issuesToConsider
                consentSection.htmlContent = ConsiderLongText
            }
            else if contentSectionType == .StudyTasks {
                consentSection.summary = riskToPrivacy
                consentSection.htmlContent = sharingResearchString
            }
            else if contentSectionType == .Withdrawing {
                consentSection.summary = withdrawing
                consentSection.htmlContent = withDrawingString
            }
            
            return consentSection
        }
        
        /*
        This is an example of a section that is only in the review document
        or only in the generated PDF, and is not displayed in `ORKVisualConsentStep`.
        */
        let consentSection = ORKConsentSection(type: .OnlyInDocument)
        consentSection.summary = NSLocalizedString(".OnlyInDocument Scene Summary", comment: "")
        consentSection.title = NSLocalizedString(".OnlyInDocument Scene", comment: "")
        consentSection.content = PotentialBenefitsLong
        
        consentSections += [consentSection]
        
        // Set the sections on the document after they've been created.
        consentDocument.sections = consentSections
        
        return consentDocument
    }

    private var consentSteps: [ORKStep] {
        /*
        Informed consent starts by presenting an animated sequence conveying
        the main points of your consent document.
        */
        let visualConsentStep = ORKVisualConsentStep(identifier: String(Identifier.VisualConsentStep), document: consentDocument)
        
        let investigatorShortDescription = NSLocalizedString("Johns Hopkins University", comment: "")
        let investigatorLongDescription = NSLocalizedString("Johns Hopkins University and its partners", comment: "")
        let localizedLearnMoreHTMLContent = NSLocalizedString("This study gives you the option to share your data in 2 ways:</p><p><strong>1- Share broadly with the research world:</strong>  You can choose to share your coded study data with qualified researchers worldwide for use in this research and beyond. Coded study data is data that does not include personal information such as your name or email. Qualified researchers are registered users of Synapse who have agreed to use the data in an ethical manner for research purposes, and have agreed to not attempt to re-identify you. If you choose to share your coded study data, the coded data will be added to a shared dataset available to qualified researchers on the Sage Bionetworks Synapse servers. (www.synapse.org). Johns Hopkins University will have no oversight onthe future research that qualified researchers may conduct with the coded study data.</p><p><strong>2- Share with Johns Hopkins University and its partners only:</strong> You can choose to share your study data only with the study team and its partners. The study team includes the sponsor of the research and any other researchers or partners named in the consent document. Sharing your data only with Johns Hopkins means that your data will not be made available to anyone other than those listed inthe consent document and for the purposes of this study only.</p><p>If required by law, your data (study data and account information), and the signed consent form may be disclosed to:</p><ul><li>The US National Institute of health, Department of Health and Human Services agencies, Office for Human Research Protection, and other agencies as required,</li><li>Institutional Review Board who monitors the safety, effectiveness and conduct of the research being conducted,</li><li>Others, if the law requires</li></ul><p>The results of this research study may be presented at meetings or in publications. If the results of this study are made public, only coded study data will be used, that is, your personal information will not be disclosed.</p><p>You can change the data sharing setting though the app preference at anytime.  For additional information review the study website <a href='http://MetabolicCompass.org'>MetabolicCompass.org</a> </p></body>", comment: "")
        
        /*
        If you want to share the data you collect with other researchers for
        use in other studies beyond this one, it is best practice to get
        explicit permission from the participant. Use the consent sharing step
        for this.
        */
        let sharingConsentStep = ORKConsentSharingStep(identifier: String(Identifier.ConsentSharingStep), investigatorShortDescription: investigatorShortDescription, investigatorLongDescription: investigatorLongDescription, localizedLearnMoreHTMLContent: localizedLearnMoreHTMLContent)
        
        /*
        After the visual presentation, the consent review step displays
        your consent document and can obtain a signature from the participant.
        
        The first signature in the document is the participant's signature.
        This effectively tells the consent review step which signatory is
        reviewing the document.
        */
        let signature = consentDocument.signatures!.first
        
        let reviewConsentStep = ORKConsentReviewStep(identifier: String(Identifier.ConsentReviewStep), signature: signature, inDocument: consentDocument)
        
        // In a real application, you would supply your own localized text.
        reviewConsentStep.text = ConsiderLongText
        reviewConsentStep.reasonForConsent = welcomeSectionText
        
        return [
            visualConsentStep,
            sharingConsentStep,
            reviewConsentStep
        ]
    }
    
    private func consentTaskWithEligibilitySection(withEligibility: Bool = true) -> ORKTask {
        if withEligibility {
            let consentTask = ORKNavigableOrderedTask(identifier: String(Identifier.EligibilityAndConsentTask), steps: Array([eligibilitySteps, consentSteps].flatten()))
            
            // Build navigation rules.
            var resultSelector = ORKResultSelector(stepIdentifier: String(Identifier.EligibilityFormStep), resultIdentifier: String(Identifier.EligibilityFormItem01))
            let predicateFormItem01 = ORKResultPredicate.predicateForBooleanQuestionResultWithResultSelector(resultSelector, expectedAnswer: true)
            
            resultSelector = ORKResultSelector(stepIdentifier: String(Identifier.EligibilityFormStep), resultIdentifier: String(Identifier.EligibilityFormItem02))
            let predicateFormItem02 = ORKResultPredicate.predicateForBooleanQuestionResultWithResultSelector(resultSelector, expectedAnswer: true)
            
            resultSelector = ORKResultSelector(stepIdentifier: String(Identifier.EligibilityFormStep), resultIdentifier: String(Identifier.EligibilityFormItem03))
            let predicateFormItem03 = ORKResultPredicate.predicateForBooleanQuestionResultWithResultSelector(resultSelector, expectedAnswer: true)
            
            let predicateEligible = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateFormItem01, predicateFormItem02, predicateFormItem03])
            
            let predicateRule = ORKPredicateStepNavigationRule(resultPredicates: [predicateEligible], destinationStepIdentifiers: [String(Identifier.EligibilityEligibleStep)], defaultStepIdentifier: nil, validateArrays: false)
            
            consentTask.setNavigationRule(predicateRule, forTriggerStepIdentifier:String(Identifier.EligibilityFormStep))
            
            // Add end direct rules to skip unneeded steps
            let directRule = ORKDirectStepNavigationRule(destinationStepIdentifier: ORKNullStepIdentifier)
            consentTask.setNavigationRule(directRule, forTriggerStepIdentifier:String(Identifier.EligibilityIneligibleStep))
            return consentTask
        } else {
            return ORKOrderedTask(identifier: String(Identifier.ConsentTask), steps: consentSteps)
        }
    }
    
    public func checkConsentWithBaseViewController(viewController: UIViewController, withEligibility: Bool = true, consentBlock: ConsentBlock) {
        self.consentHandler = consentBlock
        if obtainedUserConsent == false {
            let taskViewController = ORKTaskViewController(task: consentTaskWithEligibilitySection(withEligibility), taskRunUUID: nil)
            taskViewController.delegate = self
            viewController.presentViewController(taskViewController, animated: true, completion: nil)
        } else {
            self.consentHandler?(consented: true)
        }
    }
    
    // MARK: - Task view controller delegate
    
    public func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        switch reason {
        case .Completed:
            let document = consentDocument.copy() as! ORKConsentDocument
            let signatureResult = taskViewController.result.stepResultForStepIdentifier(String(Identifier.ConsentReviewStep))?.firstResult as! ORKConsentSignatureResult
            signatureResult.applyToDocument(document)
            document.makePDFWithCompletionHandler { (data, error) -> Void in
                guard error == nil else {
                    return
                }
                let path = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent("consent.pdf")
                print(path)
                self.setConsentFilePath(path)
                data!.writeToFile(path, atomically: true)
            }
            setUserConsentObtained()
        case .Discarded:
            break
        case .Failed:
            print(error)
        case .Saved:
            break
        }
        taskViewController.dismissViewControllerAnimated(true) {
            self.consentHandler?(consented: reason == .Completed)
        }
    }
    
}
