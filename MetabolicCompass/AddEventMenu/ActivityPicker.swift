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

    var itemContentViews: [UIView!]

    override init() {
        self.itemType = nil
        self.items = []
        self.data = [:]
        self.current = -1
        self.itemContentViews = []
    }

    init(itemType: String? = nil, items: [String], data: [String:AnyObject]) {
        self.itemType = itemType
        self.items = items
        self.data = data
        self.current = -1
        self.itemContentViews = [UIView!](count: self.items.count, repeatedValue: nil)
    }

    func refreshData(itemType: String? = nil, items: [String], data: [String:AnyObject]) {
        self.itemType = itemType
        self.items = items
        self.data = data
        self.current = -1
        self.itemContentViews = [UIView!](count: self.items.count, repeatedValue: nil)
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
            if itemContentViews[index] != nil {
                if item == index { continue }
                else {
                    itemContentViews[index].superview?.layer.borderWidth = 0.0
                    itemContentViews[index].superview?.userInteractionEnabled = false
                }
            }
        }

        Async.main(after: 0.2) {
            self.itemContentViews[item].tag = item
            self.itemContentViews[item].superview?.tag = item
            self.itemContentViews[item].superview?.layer.borderWidth = 2.0
            if !self.selectionProcessing {
                self.itemContentViews[item].superview?.userInteractionEnabled = true
            }
        }
    }

    func configureItemContentView(view: UIView, item: Int) {
        if itemContentViews[item] == nil || itemContentViews[item] != view {
            itemContentViews[item] = view
            itemContentViews[item].tag = item
            itemContentViews[item].superview?.layer.borderColor = UIColor.ht_carrotColor().CGColor
            itemContentViews[item].superview?.layer.cornerRadius = 8
            itemContentViews[item].superview?.layer.masksToBounds = true

            let press = UILongPressGestureRecognizer(target: self, action: #selector(itemSelected(_:)))
            press.minimumPressDuration = EventPickerPressDuration
            press.delegate = self
            itemContentViews[item].superview?.tag = item
            itemContentViews[item].superview?.userInteractionEnabled = true
            itemContentViews[item].superview?.addGestureRecognizer(press)
        }
    }

    func pickerView(pickerView: AKPickerView, configureLabel label: UILabel, forItem item: Int) {
        configureItemContentView(label, item: item)
    }

    func startProcessingSelection(selected: Int) {
        log.info("Processing selection \(selected)")
        if let delegate = delegate {
            if selected == current {
                // Disable all recognizers and mark the selection as processing to prevent further interaction.
                log.info("Processing selection \(selected) disabling and invoking delegate")
                selectionProcessing = true
                itemContentViews.forEach {
                    if let view = $0 {
                        view.superview?.userInteractionEnabled = false
                        view.superview?.gestureRecognizers?.forEach { g in g.enabled = false }
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
        itemContentViews.enumerate().forEach {
            if let view = $0.1 {
                view.superview?.gestureRecognizers?.forEach { g in g.enabled = true }
                if $0.0 == current { view.superview?.userInteractionEnabled = true }
            }
        }
    }

    func itemSelected(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            if let index = sender.view?.tag {
                itemContentViews[index].superview?.layer.borderColor = UIColor.ht_jayColor().CGColor
            }
        }
        if sender.state == .Ended {
            if let index = sender.view?.tag {
                itemContentViews[index].superview?.layer.borderColor = UIColor.ht_carrotColor().CGColor
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

