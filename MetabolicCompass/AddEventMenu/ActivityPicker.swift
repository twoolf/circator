//
//  ActivityPicker.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 9/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Async
import Former
import AKPickerView_Swift

let EventPickerPressDuration = 0.2

public protocol ManageEventMenuDelegate: class {
    func manageEventMenu(menu: ManageEventMenu, didSelectIndex idx: Int)
    func manageEventMenuDidFinishAnimationClose(menu: ManageEventMenu)
    func manageEventMenuDidFinishAnimationOpen(menu: ManageEventMenu)
    func manageEventMenuWillAnimateOpen(menu: ManageEventMenu)
    func manageEventMenuWillAnimateClose(menu: ManageEventMenu)
}

protocol PickerManagerSelectionDelegate {
    func pickerItemSelected(pickerManager: PickerManager, itemType: String?, index: Int, item: String, data: AnyObject?) -> Void
}

class PickerManager: NSObject, AKPickerViewDelegate, AKPickerViewDataSource, UIGestureRecognizerDelegate {
    var delegate: PickerManagerSelectionDelegate! = nil
    var selectionProcessing: Bool = false

    var itemType: String?

    var items: [String]
    var data : [String:AnyObject]
    var current: Int

    var labels: [UILabel!]

    override init() {
        self.itemType = nil
        self.items = []
        self.data = [:]
        self.current = -1
        self.labels = []
    }

    init(itemType: String? = nil, items: [String], data: [String:AnyObject]) {
        self.itemType = itemType
        self.items = items
        self.data = data
        self.current = -1
        self.labels = [UILabel!](count: self.items.count, repeatedValue: nil)
    }

    func refreshData(itemType: String? = nil, items: [String], data: [String:AnyObject]) {
        self.itemType = itemType
        self.items = items
        self.data = data
        self.current = -1
        self.labels = [UILabel!](count: self.items.count, repeatedValue: nil)
    }

    // MARK: - AKPickerViewDataSource
    func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
        return self.data.count
    }

    func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String {
        return self.items[item]
    }

    func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
        current = item

        for index in (0..<items.count) {
            if labels[index] != nil {
                if item == index { continue }
                else {
                    labels[index].superview?.layer.borderWidth = 0.0
                    labels[index].superview?.userInteractionEnabled = false
                }
            }
        }

        Async.main(after: 0.2) {
            self.labels[item].tag = item
            self.labels[item].superview?.tag = item
            self.labels[item].superview?.layer.borderWidth = 2.0
            if !self.selectionProcessing {
                self.labels[item].superview?.userInteractionEnabled = true
            }
        }
    }

    func pickerView(pickerView: AKPickerView, configureLabel label: UILabel, forItem item: Int) {
        if labels[item] == nil || labels[item] != label {
            labels[item] = label
            labels[item].tag = item
            labels[item].superview?.layer.borderColor = UIColor.ht_carrotColor().CGColor
            labels[item].superview?.layer.cornerRadius = 8
            labels[item].superview?.layer.masksToBounds = true

            let press = UILongPressGestureRecognizer(target: self, action: #selector(itemSelected(_:)))
            press.minimumPressDuration = EventPickerPressDuration
            press.delegate = self
            labels[item].superview?.tag = item
            labels[item].superview?.userInteractionEnabled = true
            labels[item].superview?.addGestureRecognizer(press)
        }

    }

    func startProcessingSelection(selected: Int) {
        log.info("Processing selection \(selected)")
        if let delegate = delegate {
            if selected == current {
                // Disable all recognizers and mark the selection as processing to prevent further interaction.
                log.info("Processing selection \(selected) disabling and invoking delegate")
                selectionProcessing = true
                labels.forEach {
                    if let lbl = $0 {
                        lbl.superview?.userInteractionEnabled = false
                        lbl.superview?.gestureRecognizers?.forEach { g in g.enabled = false }
                    }
                }
                delegate.pickerItemSelected(self, itemType: itemType, index: selected, item: getSelectedItem(), data: getSelectedValue())
            }
            else {
                log.error("PickerManager: Selected non-current index \(current) \(selected)")
            }
        } else {
            log.warning("PickerManager: No delegate found")
        }
    }

    func finishProcessingSelection() {
        selectionProcessing = false
        labels.enumerate().forEach {
            if let lbl = $0.1 {
                lbl.superview?.gestureRecognizers?.forEach { g in g.enabled = true }
                if $0.0 == current { lbl.superview?.userInteractionEnabled = true }
            }
        }
    }

    func itemSelected(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            if let index = sender.view?.tag {
                labels[index].superview?.layer.borderColor = UIColor.ht_jayColor().CGColor
            }
        }
        if sender.state == .Ended {
            if let index = sender.view?.tag {
                labels[index].superview?.layer.borderColor = UIColor.ht_carrotColor().CGColor
                startProcessingSelection(index)
            }
        }
    }

    func getSelectedItem() -> String { return current < 0 && items.count > 0 ? items[0] : "" }
    func getSelectedValue() -> AnyObject? { return current < 0 && items.count > 0 ? data[items[0]] : data[items[current]] }
}

/// AKPickerViews as Former cells/rows.
public class AKPickerCell: FormCell, AKPickerFormableRow {

    internal var imageview: UIImageView! = nil
    internal var picker: AKPickerView! = nil
    internal var manager: PickerManager! = nil

    public override func updateWithRowFormer(rowFormer: RowFormer) {
        super.updateWithRowFormer(rowFormer)
    }

    public override func setup() {
        selectionStyle = .None

        imageview = UIImageView(frame: CGRect.zero)
        imageview.contentMode = .ScaleAspectFit

        manager = PickerManager()

        // Delete Recent picker.
        picker = AKPickerView()
        picker.delegate = manager
        picker.dataSource = manager
        picker.interitemSpacing = 50

        let pickerFont = UIFont(name: "GothamBook", size: 18.0)!
        picker.font = pickerFont
        picker.highlightedFont = pickerFont

        picker.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
        picker.highlightedTextColor = UIColor.whiteColor()
        picker.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        picker.reloadData()

        imageview.translatesAutoresizingMaskIntoConstraints = false
        picker.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageview)
        contentView.addSubview(picker)

        let pickerConstraints : [NSLayoutConstraint] = [
            contentView.topAnchor.constraintEqualToAnchor(imageview.topAnchor),
            contentView.bottomAnchor.constraintEqualToAnchor(imageview.bottomAnchor),
            contentView.topAnchor.constraintEqualToAnchor(picker.topAnchor),
            contentView.bottomAnchor.constraintEqualToAnchor(picker.bottomAnchor),
            contentView.leadingAnchor.constraintEqualToAnchor(imageview.leadingAnchor, constant: -20),
            contentView.trailingAnchor.constraintEqualToAnchor(picker.trailingAnchor, constant: 20),
            picker.leadingAnchor.constraintEqualToAnchor(imageview.trailingAnchor)
        ]

        contentView.addConstraints(pickerConstraints)
    }

    public func formPicker() -> AKPickerView? {
        return picker
    }
}

public protocol AKPickerFormableRow {
    func formPicker() -> AKPickerView?
}

public class AKPickerRowFormer<T: UITableViewCell where T: AKPickerFormableRow> : BaseRowFormer<T>, Formable {
    public required init(instantiateType: Former.InstantiateType = .Class, cellSetup: (T -> Void)? = nil) {
        super.init(instantiateType: instantiateType, cellSetup: cellSetup)
    }
    
    public override func update() {
        super.update()
    }
}

